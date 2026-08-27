import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'appwrite_client.dart';
import 'appwrite_config.dart';

/// Repository for pending email verifications — `pending_subscriptions` collection.
///
/// Collection: `pending_subscriptions`
/// Attributes:
///   email: string (required, unique) — normalized lowercase
///   verification_token: string (required, unique) — uuid
///   expires_at: datetime (required) — now + 24h
///   created_at: datetime (required)
///   source: string (optional, default 'home_newsletter')
/// Indexes: email unique, verification_token unique, expires_at
class PendingSubscriptionRepository {
  static String get _db => AppwriteConfig.databaseId;
  static String get _col => AppwriteConfig.pendingSubscriptionsCollectionId;

  // In-memory mock store for offline / test mode (when Appwrite not initialized)
  static final Map<String, Map<String, dynamic>> _mockByToken = {};
  static final Map<String, Map<String, dynamic>> _mockByEmail = {};
  static void clearMock() {
    _mockByToken.clear();
    _mockByEmail.clear();
  }

  static Map<String, dynamic> _docToMap(models.Document doc) {
    final m = Map<String, dynamic>.from(doc.data);
    m['id'] = doc.$id;
    m['\$id'] = doc.$id;
    m['\$createdAt'] = doc.$createdAt;
    return m;
  }

  /// Create or update pending record for [email] with [token] and [expiresAt].
  /// Returns document map on success, null on failure.
  static Future<Map<String, dynamic>?> createPending({
    required String email,
    required String token,
    required DateTime expiresAt,
    String source = 'home_newsletter',
  }) async {
    final normalized = email.trim().toLowerCase();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final expiresIso = expiresAt.toUtc().toIso8601String();
    if (!AppwriteService.isInitialized) {
      debugPrint('[PendingSub] not initialized — mock create for $normalized token=$token');
      final mockDoc = {
        '\$id': 'mock_${token.hashCode}',
        'id': 'mock_${token.hashCode}',
        'email': normalized,
        'verification_token': token,
        'expires_at': expiresIso,
        'created_at': nowIso,
        'source': source,
      };
      _mockByToken[token] = mockDoc;
      _mockByEmail[normalized] = mockDoc;
      return mockDoc;
    }
    try {
      // Upsert: if existing pending for same email, update token/expiry
      final existing = await AppwriteService.databases.listDocuments(
        databaseId: _db,
        collectionId: _col,
        queries: [Query.equal('email', normalized), Query.limit(1)],
      );
      if (existing.documents.isNotEmpty) {
        final docId = existing.documents.first.$id;
        final updated = await AppwriteService.databases.updateDocument(
          databaseId: _db,
          collectionId: _col,
          documentId: docId,
          data: {
            'verification_token': token,
            'expires_at': expiresIso,
            'created_at': nowIso,
            'source': source,
          },
        );
        return _docToMap(updated);
      }
      final created = await AppwriteService.databases.createDocument(
        databaseId: _db,
        collectionId: _col,
        documentId: ID.unique(),
        data: {
          'email': normalized,
          'verification_token': token,
          'expires_at': expiresIso,
          'created_at': nowIso,
          'source': source,
        },
      );
      return _docToMap(created);
    } catch (e) {
      debugPrint('[PendingSub] createPending failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> findByToken(String token) async {
    if (!AppwriteService.isInitialized) {
      debugPrint('[PendingSub] not initialized — mock findByToken $token');
      return _mockByToken[token];
    }
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _db,
        collectionId: _col,
        queries: [Query.equal('verification_token', token), Query.limit(1)],
      );
      if (res.documents.isEmpty) return null;
      return _docToMap(res.documents.first);
    } catch (e) {
      debugPrint('[PendingSub] findByToken failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (!AppwriteService.isInitialized) return _mockByEmail[normalized];
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _db,
        collectionId: _col,
        queries: [Query.equal('email', normalized), Query.limit(1)],
      );
      if (res.documents.isEmpty) return null;
      return _docToMap(res.documents.first);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteById(String documentId) async {
    if (!AppwriteService.isInitialized) {
      // Remove from mock store
      _mockByToken.removeWhere((k, v) => (v['\$id'] == documentId || v['id'] == documentId));
      _mockByEmail.removeWhere((k, v) => (v['\$id'] == documentId || v['id'] == documentId));
      return true;
    }
    try {
      await AppwriteService.databases.deleteDocument(databaseId: _db, collectionId: _col, documentId: documentId);
      return true;
    } catch (e) {
      debugPrint('[PendingSub] deleteById failed: $e');
      return false;
    }
  }

  static Future<bool> deleteByToken(String token) async {
    final doc = await findByToken(token);
    if (doc == null) return false;
    final id = doc['\$id'] as String? ?? doc['id'] as String?;
    if (id == null) return false;
    return deleteById(id);
  }

  static bool isExpired(Map<String, dynamic> doc) {
    final raw = doc['expires_at'] as String?;
    if (raw == null) return true;
    try {
      final exp = DateTime.parse(raw);
      return DateTime.now().toUtc().isAfter(exp.toUtc());
    } catch (_) {
      return true;
    }
  }
}
