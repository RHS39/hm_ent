import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'appwrite_client.dart';
import 'appwrite_config.dart';

/// Repository for `users` collection — manages privileges & status.
///
/// Collection: `users` (hari_om_db)
/// Attributes: see setup_appwrite.dart / appwrite.json
///  userId: string (required, unique) — Appwrite auth user $id
///  name: string (required)
///  email: string (required, unique)
///  phone: string (optional)
///  role: string (default 'customer') — admin | customer
///  privileges: string (JSON array, default '[]') — e.g. ["manage_products","manage_users"]
///  status: string (default 'active') — active | pending | blocked | inactive
///  emailVerification: boolean (default false)
///  phoneVerification: boolean (default false)
///
/// Permissions: read("users"), create/update/delete("users") with documentSecurity.
class AppwriteUserRepository {
  static String get _db => AppwriteConfig.databaseId;
  static String get _col => AppwriteConfig.usersCollectionId;

  static Map<String, dynamic> _docToMap(models.Document doc) {
    final m = Map<String, dynamic>.from(doc.data);
    m['id'] = doc.$id;
    m[r'$id'] = doc.$id;
    m[r'$createdAt'] = doc.$createdAt;
    m[r'$updatedAt'] = doc.$updatedAt;
    // normalize keys for UI
    if (!m.containsKey('userId') && m.containsKey('user_id')) m['userId'] = m['user_id'];
    if (!m.containsKey('emailVerification') && m.containsKey('email_verification')) m['emailVerification'] = m['email_verification'];
    if (!m.containsKey('phoneVerification') && m.containsKey('phone_verification')) m['phoneVerification'] = m['phone_verification'];
    // ensure id aliases
    m['id'] ??= doc.$id;
    return m;
  }

  static List<String> parsePrivileges(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    final s = raw.toString().trim();
    if (s.isEmpty || s == '[]') return [];
    // try JSON
    try {
      // simple split fallback
      final cleaned = s.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll("'", '');
      return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  static String privilegesToString(List<String> list) {
    if (list.isEmpty) return '[]';
    return '[${list.map((e) => '"$e"').join(',')}]';
  }

  static const List<String> allRoles = ['admin', 'customer'];
  static const List<String> allStatuses = ['active', 'pending', 'blocked', 'inactive'];
  // Role-specific privileges — customer vs admin are distinct
  static const List<String> adminPrivileges = [
    'manage_products',
    'manage_users',
    'manage_contacts',
    'manage_subscribers',
    'view_analytics',
    'manage_orders',
    'manage_settings',
    'manage_inventory',
  ];
  static const List<String> customerPrivileges = [
    'view_products',
    'place_orders',
    'view_orders',
    'manage_cart',
    'manage_wishlist',
    'view_invoices',
    'manage_profile',
    'contact_support',
  ];
  // Backwards compat — all combined
  static const List<String> allPrivileges = [
    'manage_products',
    'manage_users',
    'manage_contacts',
    'manage_subscribers',
    'view_analytics',
    'manage_orders',
    'manage_settings',
    'manage_inventory',
    'view_products',
    'place_orders',
    'view_orders',
    'manage_cart',
    'manage_wishlist',
    'view_invoices',
    'manage_profile',
    'contact_support',
  ];

  static List<String> privilegesForRole(String role) => role == 'admin' ? adminPrivileges : customerPrivileges;

  static bool isCollectionNotFound(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('collection_not_found') || s.contains('collection with the requested id') || (s.contains('404') && s.contains('collection'));
  }

  static String _friendlyError(Object e) {
    if (isCollectionNotFound(e)) {
      return 'Users collection not found. Please create "users" collection in Appwrite Console → Databases → hari_om_db, or run: dart run appwrite/setup_appwrite.dart --projectId=YOUR_ID --apiKey=YOUR_KEY';
    }
    if (e is AppwriteException) {
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  // ── READ ──
  static Future<List<Map<String, dynamic>>> fetchAll({int limit = 100, String? role, String? status, String? search}) async {
    if (!AppwriteService.isInitialized) return [];
    try {
      final queries = <String>[Query.orderDesc(r'$createdAt'), Query.limit(limit)];
      if (role != null && role != 'all') queries.insert(0, Query.equal('role', role));
      if (status != null && status != 'all') queries.insert(0, Query.equal('status', status));
      if (search != null && search.trim().isNotEmpty) queries.add(Query.search('name', search.trim()));
      final res = await AppwriteService.databases.listDocuments(databaseId: _db, collectionId: _col, queries: queries);
      return res.documents.map(_docToMap).toList();
    } catch (e) {
      if (isCollectionNotFound(e)) {
        debugPrint('[AppwriteUsers] users collection missing — run setup_appwrite.dart');
      } else {
        debugPrint('[AppwriteUsers] fetchAll failed: $e');
      }
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecent({int limit = 50}) => fetchAll(limit: limit);

  static Future<Map<String, dynamic>?> getById(String id) async {
    if (!AppwriteService.isInitialized) return null;
    try {
      final doc = await AppwriteService.databases.getDocument(databaseId: _db, collectionId: _col, documentId: id.trim());
      return _docToMap(doc);
    } catch (e) {
      debugPrint('[AppwriteUsers] getById failed: $e');
      return null;
    }
  }

  // ── CREATE ──
  static Future<Map<String, dynamic>?> create({
    required String userId,
    required String name,
    required String email,
    String phone = '',
    String role = 'customer',
    List<String> privileges = const [],
    String status = 'active',
    bool emailVerification = false,
    bool phoneVerification = false,
  }) async {
    if (!AppwriteService.isInitialized) throw Exception('Appwrite not configured');
    final data = {
      'userId': userId.trim(),
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'role': role,
      'privileges': privilegesToString(privileges),
      'status': status,
      'emailVerification': emailVerification,
      'phoneVerification': phoneVerification,
    };
    try {
      final doc = await AppwriteService.databases.createDocument(databaseId: _db, collectionId: _col, documentId: ID.unique(), data: data);
      return _docToMap(doc);
    } on AppwriteException catch (e) {
      if (isCollectionNotFound(e)) throw Exception(_friendlyError(e));
      rethrow;
    }
  }

  // ── UPDATE privileges / status / role ──
  static Future<Map<String, dynamic>> updatePrivilegesAndStatus({
    required String docId,
    String? role,
    List<String>? privileges,
    String? status,
  }) async {
    if (!AppwriteService.isInitialized) throw Exception('Appwrite not configured');
    final data = <String, dynamic>{};
    if (role != null) {
      if (!allRoles.contains(role)) throw ArgumentError('Invalid role $role');
      data['role'] = role;
    }
    if (privileges != null) {
      data['privileges'] = privilegesToString(privileges);
    }
    if (status != null) {
      if (!allStatuses.contains(status)) throw ArgumentError('Invalid status $status');
      data['status'] = status;
    }
    if (data.isEmpty) throw ArgumentError('No fields to update');
    try {
      final doc = await AppwriteService.databases.updateDocument(databaseId: _db, collectionId: _col, documentId: docId.trim(), data: data);
      return _docToMap(doc);
    } on AppwriteException catch (e) {
      if (isCollectionNotFound(e)) throw Exception(_friendlyError(e));
      rethrow;
    }
  }

  static Future<bool> updateStatus(String docId, String status) async {
    try {
      await updatePrivilegesAndStatus(docId: docId, status: status);
      return true;
    } catch (e) {
      debugPrint('[AppwriteUsers] updateStatus failed: $e');
      return false;
    }
  }

  static Future<bool> updateRole(String docId, String role) async {
    try {
      await updatePrivilegesAndStatus(docId: docId, role: role);
      return true;
    } catch (e) {
      debugPrint('[AppwriteUsers] updateRole failed: $e');
      return false;
    }
  }

  // ── DELETE ──
  static Future<bool> delete(String docId) async {
    if (!AppwriteService.isInitialized) throw Exception('Appwrite not configured');
    await AppwriteService.databases.deleteDocument(databaseId: _db, collectionId: _col, documentId: docId.trim());
    return true;
  }

  // ── Helpers for UI ──
  static String roleOf(Map<String, dynamic> row) => (row['role'] ?? 'customer').toString();
  static String statusOf(Map<String, dynamic> row) => (row['status'] ?? 'active').toString();
  static List<String> privilegesOf(Map<String, dynamic> row) => parsePrivileges(row['privileges']);
  static bool isEmailVerifiedOf(Map<String, dynamic> row) => row['emailVerification'] == true || row['email_verification'] == true;
}