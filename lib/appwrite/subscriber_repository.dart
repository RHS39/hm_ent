import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'appwrite_client.dart';
import 'appwrite_config.dart';

/// Repository for newsletter subscribers — `subscribers` collection.
///
/// Collection: `subscribers`
/// Attributes:
///   email: string (required, unique) — normalized lowercase
///   status: string (required, default 'active') — active|pending|unsubscribed|bounced|complained
///   subscribed_at: datetime (required)
///   updated_at: datetime (required)
///   source: string (optional, default 'home_newsletter')
///   meta: string (optional, json string)
/// Index: email unique, status, subscribed_at
class AppwriteSubscriberRepository {
  static String get _db => AppwriteConfig.databaseId;
  static String get _col => AppwriteConfig.subscribersCollectionId;

  static const String statusActive = 'active';
  static const String statusPending = 'pending';
  static const String statusUnsubscribed = 'unsubscribed';
  static const String statusBounced = 'bounced';
  static const String statusComplained = 'complained';
  static const List<String> allStatuses = [statusActive, statusPending, statusUnsubscribed, statusBounced, statusComplained];

  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
  static bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

  static Map<String, dynamic> _docToMap(models.Document doc) {
    final m = Map<String, dynamic>.from(doc.data);
    m['id'] = doc.$id;
    m['\$id'] = doc.$id;
    m['\$createdAt'] = doc.$createdAt;
    return m;
  }

  static Future<({bool success, bool alreadySubscribed, String? error})> subscribe({
    required String email,
    String source = 'home_newsletter',
    Map<String, dynamic>? meta,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) {
      return (success: false, alreadySubscribed: false, error: 'Invalid email format');
    }
    if (!AppwriteService.isInitialized) {
      debugPrint('[AppwriteSubscribers] not initialized — treating as local success for $normalized');
      return (success: true, alreadySubscribed: false, error: null);
    }
    try {
      final nowIso = DateTime.now().toIso8601String();
      // Check existing by email
      final existing = await AppwriteService.databases.listDocuments(
        databaseId: _db,
        collectionId: _col,
        queries: [Query.equal('email', normalized), Query.limit(1)],
      );
      if (existing.documents.isNotEmpty) {
        final doc = existing.documents.first;
        final curStatus = doc.data['status'] as String? ?? statusActive;
        if (curStatus == statusActive || curStatus == statusPending) {
          return (success: true, alreadySubscribed: true, error: null);
        }
        // Reactivate
        await AppwriteService.databases.updateDocument(
          databaseId: _db,
          collectionId: _col,
          documentId: doc.$id,
          data: {'status': statusActive, 'subscribed_at': nowIso, 'updated_at': nowIso, 'source': source},
        );
        debugPrint('[AppwriteSubscribers] Reactivated $normalized -> active');
        return (success: true, alreadySubscribed: false, error: null);
      }
      await AppwriteService.databases.createDocument(
        databaseId: _db,
        collectionId: _col,
        documentId: ID.unique(),
        data: {
          'email': normalized,
          'status': statusActive,
          'subscribed_at': nowIso,
          'updated_at': nowIso,
          'source': source,
          'meta': meta != null ? meta.toString() : '{}',
        },
      );
      debugPrint('[AppwriteSubscribers] Subscribed $normalized');
      return (success: true, alreadySubscribed: false, error: null);
    } on AppwriteException catch (e) {
      final msg = (e.message ?? '').toLowerCase();
      final code = e.code ?? 0;
      if (code == 409 || msg.contains('already exists') || msg.contains('duplicate') || msg.contains('unique')) {
        return (success: true, alreadySubscribed: true, error: null);
      }
      if (msg.contains('permission') || code == 403) {
        return (success: false, alreadySubscribed: false, error: 'Newsletter service is being set up. Please try again in a moment.');
      }
      debugPrint('[AppwriteSubscribers] subscribe failed: $e');
      return (success: false, alreadySubscribed: false, error: 'Could not subscribe right now. Please try again in a moment.');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('socket') || msg.contains('timeout')) {
        return (success: false, alreadySubscribed: false, error: 'Network error — please check your connection and try again.');
      }
      return (success: false, alreadySubscribed: false, error: 'Could not subscribe right now. Please try again in a moment.');
    }
  }

  static Future<bool> unsubscribe(String email) => updateStatus(email, statusUnsubscribed);

  static Future<bool> updateStatus(String email, String status) async {
    if (!allStatuses.contains(status)) return false;
    if (!AppwriteService.isInitialized) return false;
    try {
      final normalized = email.trim().toLowerCase();
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _db, collectionId: _col, queries: [Query.equal('email', normalized), Query.limit(1)]);
      if (res.documents.isEmpty) return false;
      await AppwriteService.databases.updateDocument(
        databaseId: _db, collectionId: _col, documentId: res.documents.first.$id, data: {'status': status, 'updated_at': DateTime.now().toIso8601String()});
      return true;
    } catch (e) {
      debugPrint('[AppwriteSubscribers] updateStatus failed: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecent({int limit = 100, String? statusFilter}) async {
    if (!AppwriteService.isInitialized) return [];
    try {
      final queries = <String>[Query.orderDesc('subscribed_at'), Query.limit(limit)];
      if (statusFilter != null) queries.insert(0, Query.equal('status', statusFilter));
      final res = await AppwriteService.databases.listDocuments(databaseId: _db, collectionId: _col, queries: queries);
      return res.documents.map(_docToMap).toList();
    } catch (e) {
      debugPrint('[AppwriteSubscribers] fetchRecent failed: $e');
      return [];
    }
  }

  static Future<Map<String, int>> countByStatus() async {
    final rows = await fetchRecent(limit: 1000);
    final map = <String, int>{};
    for (final r in rows) {
      final s = r['status'] as String? ?? 'unknown';
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }
}
