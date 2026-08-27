import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'appwrite_client.dart';
import 'appwrite_config.dart';

/// Repository for Contact Us messages — `contact_messages` collection.
///
/// Collection: `contact_messages`
/// Attributes:
///   name: string (required)
///   email: string (required)
///   phone: string (required)
///   address: string (required)
///   pincode: string (required)
///   district: string (required)
///   state: string (required)
///   country: string (required, default 'India')
///   message: string (required)
///   source: string (optional, default 'contact_us_page')
///   status: string (optional, default 'new')
///   created_at: datetime (auto)
class AppwriteContactRepository {
  static String get _db => AppwriteConfig.databaseId;
  static String get _col => AppwriteConfig.contactMessagesCollectionId;

  static Map<String, dynamic> _docToMap(models.Document doc) {
    final m = Map<String, dynamic>.from(doc.data);
    m['id'] = doc.$id;
    m['\$id'] = doc.$id;
    m['\$createdAt'] = doc.$createdAt;
    return m;
  }

  static Future<bool> submit({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String pincode,
    required String district,
    required String state,
    required String country,
    required String message,
    String source = 'contact_us_page',
  }) async {
    if (!AppwriteService.isInitialized) {
      debugPrint('[AppwriteContact] not initialized – skipping insert');
      return false;
    }
    try {
      await AppwriteService.databases.createDocument(
        databaseId: _db,
        collectionId: _col,
        documentId: ID.unique(),
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'pincode': pincode.trim(),
          'district': district.trim(),
          'state': state.trim(),
          'country': country.trim().isEmpty ? 'India' : country.trim(),
          'message': message.trim(),
          'source': source,
          'status': 'new',
        },
      );
      debugPrint('[AppwriteContact] Message inserted: $email');
      return true;
    } on AppwriteException catch (e) {
      debugPrint('[AppwriteContact] insert failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[AppwriteContact] insert failed: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecent({int limit = 50}) async {
    if (!AppwriteService.isInitialized) return [];
    try {
      final res = await AppwriteService.databases.listDocuments(
        databaseId: _db,
        collectionId: _col,
        queries: [Query.orderDesc('\$createdAt'), Query.limit(limit)],
      );
      return res.documents.map(_docToMap).toList();
    } catch (e) {
      debugPrint('[AppwriteContact] fetchRecent failed: $e');
      return [];
    }
  }

  static Future<bool> updateStatus(String id, String status) async {
    if (!AppwriteService.isInitialized) return false;
    try {
      await AppwriteService.databases.updateDocument(databaseId: _db, collectionId: _col, documentId: id, data: {'status': status});
      return true;
    } catch (e) {
      debugPrint('[AppwriteContact] updateStatus failed: $e');
      return false;
    }
  }
}
