import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../appwrite/appwrite_client.dart';
import '../appwrite/appwrite_config.dart';
import '../appwrite/subscriber_repository.dart';
import '../appwrite/pending_subscription_repository.dart';
import 'email_service.dart';

/// High-level subscription flow that enforces email verification.
///
/// Mirrors the backend spec:
///   POST /api/subscriptions  → requestSubscription()
///   GET  /verify-email?token → verifyToken()
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
  bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

  // In-memory mock subscribers for offline/test mode
  final Set<String> _mockSubscribers = {};
  Set<String> get mockSubscribers => _mockSubscribers;
  void clearMock() {
    _mockSubscribers.clear();
    PendingSubscriptionRepository.clearMock();
    EmailService.instance.clear();
  }

  bool isMockSubscribed(String email) => _mockSubscribers.contains(email.trim().toLowerCase());

  /// Result of a Join request.
  /// `success` true means a verification email was queued (or already subscribed).
  /// `alreadySubscribed` true means email is already active in main table.
  /// `verificationSent` true means pending record created + email queued.
  /// `error` non-null on failure.
  Future<({bool success, bool alreadySubscribed, bool verificationSent, String? error, String? token})> requestSubscription({
    required String email,
    String source = 'home_newsletter',
    String? baseUrl,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      return (success: false, alreadySubscribed: false, verificationSent: false, error: 'Please enter your email address', token: null);
    }
    if (!isValidEmail(normalized)) {
      return (success: false, alreadySubscribed: false, verificationSent: false, error: 'Please enter a valid email address (e.g., name@example.com)', token: null);
    }

    // 1. Check main subscribers — if already active, short-circuit
    try {
      if (AppwriteService.isInitialized) {
        final existing = await AppwriteService.databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.subscribersCollectionId,
          queries: [Query.equal('email', normalized), Query.limit(1)],
        );
        if (existing.documents.isNotEmpty) {
          final status = existing.documents.first.data['status'] as String? ?? AppwriteSubscriberRepository.statusActive;
          if (status == AppwriteSubscriberRepository.statusActive || status == AppwriteSubscriberRepository.statusPending) {
            return (success: true, alreadySubscribed: true, verificationSent: false, error: null, token: null);
          }
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionService] check existing failed: $e');
      // continue — don't block verification on read failure
    }

    // If Appwrite not configured, mock verification flow locally
    if (!AppwriteService.isInitialized) {
      if (_mockSubscribers.contains(normalized)) {
        return (success: true, alreadySubscribed: true, verificationSent: false, error: null, token: null);
      }
      final token = _generateToken();
      final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 24));
      await PendingSubscriptionRepository.createPending(email: normalized, token: token, expiresAt: expiresAt, source: source);
      await EmailService.instance.sendVerificationEmail(email: normalized, token: token, baseUrl: baseUrl);
      return (success: true, alreadySubscribed: false, verificationSent: true, error: null, token: token);
    }

    // 2. Generate secure token — use Appwrite ID.unique + random suffix for entropy
    final token = _generateToken();
    final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 24));

    // 3. Store pending
    final pending = await PendingSubscriptionRepository.createPending(
      email: normalized,
      token: token,
      expiresAt: expiresAt,
      source: source,
    );
    if (pending == null) {
      return (success: false, alreadySubscribed: false, verificationSent: false, error: 'Could not create verification request. Please try again.', token: null);
    }

    // 4. Send email (background job)
    final emailed = await EmailService.instance.sendVerificationEmail(email: normalized, token: token, baseUrl: baseUrl);
    if (!emailed) {
      debugPrint('[SubscriptionService] email send failed for $normalized, pending kept');
    }

    return (success: true, alreadySubscribed: false, verificationSent: true, error: null, token: token);
  }

  /// Verification endpoint: GET /verify-email?token=XXX
  /// Returns (success, error, email) tuple.
  Future<({bool success, String? error, String? email})> verifyToken(String rawToken) async {
    final token = rawToken.trim();
    if (token.isEmpty) {
      return (success: false, error: 'Invalid verification link — missing token.', email: null);
    }

    // Non-initialized mode — simulate using in-memory pending store
    if (!AppwriteService.isInitialized) {
      final doc = await PendingSubscriptionRepository.findByToken(token);
      if (doc == null) {
        // fallback to outbox check
        if (EmailService.instance.outbox.any((m) => m['token'] == token)) {
          final email = EmailService.instance.outbox.firstWhere((m) => m['token'] == token)['email'];
          EmailService.instance.outbox.removeWhere((m) => m['token'] == token);
          _mockSubscribers.add(email!.toLowerCase());
          return (success: true, error: null, email: email);
        }
        return (success: false, error: 'Invalid verification link — token not found. It may have been used already.', email: null);
      }
      if (PendingSubscriptionRepository.isExpired(doc)) {
        final id = doc['\$id'] as String? ?? doc['id'] as String?;
        if (id != null) await PendingSubscriptionRepository.deleteById(id);
        return (success: false, error: 'This verification link has expired (24h). Please request a new one.', email: null);
      }
      final email = (doc['email'] as String?)?.toLowerCase() ?? '';
      if (email.isEmpty) return (success: false, error: 'Invalid pending record — missing email.', email: null);
      if (_mockSubscribers.contains(email)) {
        final id = doc['\$id'] as String? ?? doc['id'] as String?;
        if (id != null) await PendingSubscriptionRepository.deleteById(id);
        return (success: true, error: null, email: email);
      }
      _mockSubscribers.add(email);
      final id = doc['\$id'] as String? ?? doc['id'] as String?;
      if (id != null) await PendingSubscriptionRepository.deleteById(id);
      EmailService.instance.outbox.removeWhere((m) => m['token'] == token);
      return (success: true, error: null, email: email);
    }

    // 1. Fetch pending by token
    final doc = await PendingSubscriptionRepository.findByToken(token);
    if (doc == null) {
      return (success: false, error: 'Invalid verification link — token not found. It may have been used already.', email: null);
    }

    // 2. Check expiry
    if (PendingSubscriptionRepository.isExpired(doc)) {
      // Delete expired pending
      final id = doc['\$id'] as String? ?? doc['id'] as String?;
      if (id != null) await PendingSubscriptionRepository.deleteById(id);
      return (success: false, error: 'This verification link has expired (24h). Please request a new one.', email: null);
    }

    final email = (doc['email'] as String?)?.toLowerCase() ?? '';
    final source = doc['source'] as String? ?? 'home_newsletter';
    if (email.isEmpty) {
      return (success: false, error: 'Invalid pending record — missing email.', email: null);
    }

    // 3. Insert into main subscribers table (active)
    // Re-check not already subscribed (race)
    try {
      final existing = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.subscribersCollectionId,
        queries: [Query.equal('email', email), Query.limit(1)],
      );
      if (existing.documents.isNotEmpty) {
        // Already subscribed — clean pending and succeed
        final id = doc['\$id'] as String? ?? doc['id'] as String?;
        if (id != null) await PendingSubscriptionRepository.deleteById(id);
        return (success: true, error: null, email: email);
      }
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await AppwriteService.databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.subscribersCollectionId,
        documentId: ID.unique(),
        data: {
          'email': email,
          'status': AppwriteSubscriberRepository.statusActive,
          'subscribed_at': nowIso,
          'updated_at': nowIso,
          'source': source,
          'meta': '{"verified_via":"email_token"}',
        },
      );
    } on AppwriteException catch (e) {
      final code = e.code ?? 0;
      final msg = (e.message ?? '').toLowerCase();
      if (code == 409 || msg.contains('unique') || msg.contains('already exists')) {
        // Duplicate — treat as already subscribed
        final id = doc['\$id'] as String? ?? doc['id'] as String?;
        if (id != null) await PendingSubscriptionRepository.deleteById(id);
        return (success: true, error: null, email: email);
      }
      return (success: false, error: 'Verification failed — could not save subscription. Please try again.', email: null);
    } catch (e) {
      return (success: false, error: 'Verification failed: $e', email: null);
    }

    // 4. Delete pending
    final pendingId = doc['\$id'] as String? ?? doc['id'] as String?;
    if (pendingId != null) await PendingSubscriptionRepository.deleteById(pendingId);

    return (success: true, error: null, email: email);
  }

  String _generateToken() {
    // Use Appwrite ID.unique (20 chars) + random hex for extra entropy + timestamp
    final base = ID.unique(); // e.g. 65f...
    final rnd = Random.secure();
    final suffix = List.generate(12, (_) => rnd.nextInt(16).toRadixString(16)).join();
    return '${base}_$suffix';
  }
}
