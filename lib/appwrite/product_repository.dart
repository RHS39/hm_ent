import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'appwrite_client.dart';
import 'appwrite_config.dart';

/// Repository for products — `products` collection.
///
/// Collection: `products` (Appwrite Database `hari_om_db`)
/// Attributes (create in Appwrite Console > Databases > hari_om_db > products):
///   product_id: string (required, unique) — e.g. "01"
///   name: string (required, unique) — product name
///   price: double (required)
///   description: string (optional)
///   icon: string (optional, default 'spa')
///   category: string (optional, default 'Jaggery')
///   stock_quantity: integer (optional, default 100)
///   moq: integer (optional, default 1) — minimum order quantity
///   image_url: string (optional, url)
///   is_active: boolean (optional, default true)
///
/// Permissions: allow `any` read, `users` create/update/delete (or `team:admin` in production).
/// Indexes: `product_id` unique, `name` unique, `category`, `is_active`.

IconData iconFromName(String name) {
  const map = {
    'grain': Icons.grain,
    'spa': Icons.spa,
    'water_drop': Icons.water_drop,
    'eco': Icons.eco,
    'local_florist': Icons.local_florist,
    'square': Icons.square_outlined,
    'cookie': Icons.cookie,
    'local_cafe': Icons.local_cafe,
    'card_giftcard': Icons.card_giftcard,
    'inventory_2': Icons.inventory_2,
    'shopping_bag': Icons.shopping_bag,
    'category': Icons.category,
  };
  return map[name] ?? Icons.spa;
}

const List<String> allIconNames = [
  'grain', 'spa', 'water_drop', 'eco', 'local_florist', 'square',
  'cookie', 'local_cafe', 'card_giftcard', 'inventory_2',
  'shopping_bag', 'category',
];

const List<String> productCategories = [
  'Powder', 'Cubes', 'Liquid', 'Flavored', 'Block', 'Granular',
  'Chikki', 'Blend', 'Syrup', 'Hamper', 'Other',
];

class AppwriteProductRepository {
  static String get _db => AppwriteConfig.databaseId;
  static String get _col => AppwriteConfig.productsCollectionId;
  static const Duration _timeout = Duration(seconds: 12);

  // ── Helpers ──
  static Future<T> _withTimeout<T>(Future<T> f, String op) =>
      f.timeout(_timeout, onTimeout: () => throw Exception('$op timed out after ${_timeout.inSeconds}s'));

  static Map<String, dynamic> _docToMap(models.Document doc) {
    final m = Map<String, dynamic>.from(doc.data);
    m['id'] = doc.$id; // Appwrite doc id -> `id` like Supabase uuid
    m['\$id'] = doc.$id;
    m['\$createdAt'] = doc.$createdAt;
    m['\$updatedAt'] = doc.$updatedAt;
    return m;
  }

  static String _friendly(AppwriteException e) {
    final code = e.code ?? 0;
    final msg = (e.message ?? '').toLowerCase();
    if (code == 409 || msg.contains('already exists') || msg.contains('duplicate') || msg.contains('unique')) {
      if (msg.contains('product_id')) return 'Product ID already exists.';
      if (msg.contains('name')) return 'Product name already exists.';
      return 'Duplicate value: ${e.message}';
    }
    if (code == 401 || msg.contains('unauthorized') || msg.contains('auth')) return 'Session expired. Please log in again.';
    if (code == 403 || msg.contains('permission') || msg.contains('denied')) return 'Permission denied. Ensure admin login.';
    if (code == 404 || msg.contains('not found')) return 'Not found: ${e.message}';
    return e.message ?? e.toString();
  }

  static bool _isMissingAttributeError(dynamic e) {
    final s = e.toString().toLowerCase();
    // AppwriteException message is often "Invalid document structure: Unknown attribute: \"image_2\""
    return s.contains('unknown attribute') || s.contains('attribute not found') || s.contains('invalid document structure');
  }

  static bool _payloadHasExtraImages(Map<String, dynamic> p) {
    // Also detect cleared image_url (empty string) — may fail if attribute doesn't exist
    final hasClearedMain = p['image_url'] is String && (p['image_url'] as String).isEmpty;
    return p.containsKey('image_2') || p.containsKey('image_3') || hasClearedMain;
  }
  static bool _payloadHasMoq(Map<String, dynamic> p) => p.containsKey('moq');

  // ──────────────────────────────────────────────
  //  READ — public (for shop)
  // ──────────────────────────────────────────────

  /// Fetch all active products (public shop). Mirrors `ProductRepository.fetchActiveProducts`.
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    if (!AppwriteService.isInitialized) return [];
    try {
      final res = await _withTimeout(
        AppwriteService.databases.listDocuments(
          databaseId: _db,
          collectionId: _col,
          queries: [Query.orderAsc('product_id'), Query.limit(100)],
        ),
        'fetchProducts',
      );
      return res.documents.map(_docToMap).toList();
    } catch (e) {
      debugPrint('[AppwriteProducts] fetchProducts failed: $e');
      return [];
    }
  }

  /// Fetch active products with optional filters.
  static Future<List<Map<String, dynamic>>> fetchActiveProducts({String? category, String? searchQuery}) async {
    if (!AppwriteService.isInitialized) return [];
    try {
      final queries = <String>[];
      if (category != null && category.isNotEmpty) queries.add(Query.equal('category', category));
      if (searchQuery != null && searchQuery.isNotEmpty) queries.add(Query.search('name', searchQuery));
      queries.add(Query.orderAsc('product_id'));
      queries.add(Query.limit(100));
      final res = await _withTimeout(
        AppwriteService.databases.listDocuments(databaseId: _db, collectionId: _col, queries: queries),
        'fetchActiveProducts',
      );
      return res.documents.map(_docToMap).toList();
    } catch (e) {
      debugPrint('[AppwriteProducts] fetchActiveProducts failed: $e');
      return [];
    }
  }

  /// Paginated fetch for shop — 10 per page, supports category/search/sort and returns total.
  /// Use for modern shopping pagination (server-side).
  static Future<({List<Map<String, dynamic>> items, int total})> fetchProductsPaginated({
    int limit = 10,
    int offset = 0,
    String? category,
    String? searchQuery,
    String sortBy = 'product_id',
    bool ascending = true,
  }) async {
    if (!AppwriteService.isInitialized) return (items: <Map<String, dynamic>>[], total: 0);
    try {
      final queries = <String>[];
      if (category != null && category.isNotEmpty && category != 'All') {
        queries.add(Query.equal('category', category));
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queries.add(Query.search('name', searchQuery.trim()));
      }
      queries.add(ascending ? Query.orderAsc(sortBy) : Query.orderDesc(sortBy));
      queries.add(Query.limit(limit));
      queries.add(Query.offset(offset));
      final res = await _withTimeout(
        AppwriteService.databases.listDocuments(databaseId: _db, collectionId: _col, queries: queries),
        'fetchProductsPaginated',
      );
      return (items: res.documents.map(_docToMap).toList(), total: res.total);
    } catch (e) {
      debugPrint('[AppwriteProducts] fetchProductsPaginated failed: $e');
      return (items: <Map<String, dynamic>>[], total: 0);
    }
  }

  /// Fetch all products for admin (includes inactive). Mirrors `ProductDatabaseService.getAllAdminProducts`.
  static Future<List<Map<String, dynamic>>> getAllAdminProducts() async {
    if (!AppwriteService.isInitialized) throw Exception('Appwrite not configured.');
    try {
      final res = await _withTimeout(
        AppwriteService.databases.listDocuments(
          databaseId: _db,
          collectionId: _col,
          queries: [Query.orderDesc('\$createdAt'), Query.limit(100)],
        ),
        'getAllAdminProducts',
      );
      return res.documents.map(_docToMap).toList();
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  static Future<Map<String, dynamic>?> fetchById(String id) async => getProductById(id);

  static Future<Map<String, dynamic>?> getProductById(String id) async {
    if (!AppwriteService.isInitialized) return null;
    try {
      final doc = await _withTimeout(
        AppwriteService.databases.getDocument(databaseId: _db, collectionId: _col, documentId: id.trim()),
        'getProductById',
      );
      return _docToMap(doc);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      debugPrint('[AppwriteProducts] getProductById failed: $e');
      return null;
    } catch (e) {
      debugPrint('[AppwriteProducts] getProductById failed: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  //  CREATE / UPDATE / DELETE — admin
  // ──────────────────────────────────────────────

  static Map<String, dynamic> _normalizeForWrite(Map<String, dynamic> data, {required bool isCreate}) {
    final out = <String, dynamic>{};
    T? pick<T>(List<String> keys) {
      for (final k in keys) {
        if (data.containsKey(k) && data[k] != null) {
          final v = data[k];
          if (v is String && v.trim().isEmpty) continue;
          return v as T;
        }
      }
      return null;
    }

    String? spick(List<String> keys) {
      final v = pick<dynamic>(keys);
      if (v == null) return null;
      return v.toString().trim();
    }

    final name = spick(['name']);
    if (name != null && name.isNotEmpty) out['name'] = name;
    if (data.containsKey('description')) out['description'] = (data['description'] ?? '').toString().trim();
    final rp = pick<dynamic>(['price']);
    if (rp != null) {
      final price = rp is num ? rp.toDouble() : double.tryParse(rp.toString().replaceAll(RegExp(r'[₹,\s]'), '').replaceAll(RegExp(r'[^0-9.\-]'), ''));
      if (price != null) out['price'] = price;
    }
    final rs = pick<dynamic>(['stock_quantity', 'stockQuantity', 'stock']);
    if (rs != null) {
      final qty = rs is int ? rs : int.tryParse(rs.toString().replaceAll(RegExp(r'[,_\s]'), '').replaceAll(RegExp(r'[^0-9\-]'), ''));
      if (qty != null) out['stock_quantity'] = qty;
    }
    final rm = pick<dynamic>(['moq', 'minimum_order_quantity', 'min_order_quantity', 'min_qty']);
    if (rm != null) {
      final moq = rm is int ? rm : int.tryParse(rm.toString().replaceAll(RegExp(r'[^0-9\-]'), ''));
      if (moq != null) out['moq'] = moq.clamp(1, 999);
    }
    final img = spick(['image_url', 'imageUrl', 'image', 'image_1']);
    if (img != null && img.isNotEmpty) {
      out['image_url'] = img;
    } else if (data.containsKey('image_url') || data.containsKey('imageUrl') || data.containsKey('image') || data.containsKey('image_1')) {
      out['image_url'] = ''; // empty string tells Appwrite to clear the field
    }
    final img2 = spick(['image_2', 'image2', 'imageUrl2', 'image_url_2']);
    if (img2 != null && img2.isNotEmpty) {
      out['image_2'] = img2;
    } else if (data.containsKey('image_2') || data.containsKey('image2') || data.containsKey('imageUrl2') || data.containsKey('image_url_2')) {
      out['image_2'] = ''; // empty string tells Appwrite to clear the field
    }
    final img3 = spick(['image_3', 'image3', 'imageUrl3', 'image_url_3']);
    if (img3 != null && img3.isNotEmpty) {
      out['image_3'] = img3;
    } else if (data.containsKey('image_3') || data.containsKey('image3') || data.containsKey('imageUrl3') || data.containsKey('image_url_3')) {
      out['image_3'] = ''; // empty string tells Appwrite to clear the field
    }
    final cat = spick(['category']);
    if (cat != null && cat.isNotEmpty) out['category'] = cat;
    if (data.containsKey('is_active') || data.containsKey('isActive')) {
      final raw = data['is_active'] ?? data['isActive'];
      if (raw is bool) out['is_active'] = raw;
      else if (raw is String) out['is_active'] = raw.toLowerCase() == 'true';
      else if (raw is int) out['is_active'] = raw != 0;
    }
    final pid = spick(['product_id', 'productId']);
    if (pid != null && pid.isNotEmpty) out['product_id'] = pid;
    final icon = spick(['icon']);
    if (icon != null && icon.isNotEmpty) out['icon'] = icon;
    return out;
  }

  static void _validate(Map<String, dynamic> p, {required bool isCreate}) {
    if (isCreate) {
      if ((p['name'] ?? '').toString().trim().isEmpty) throw ArgumentError('Product name is required');
      final price = p['price'];
      if (price == null || (price is num && price <= 0)) throw ArgumentError('Valid price (>0) required');
    } else {
      if (p.containsKey('name') && (p['name'] ?? '').toString().trim().isEmpty) throw ArgumentError('Name cannot be empty');
      if (p.containsKey('price') && p['price'] is num && (p['price'] as num) <= 0) throw ArgumentError('Price must be >0');
    }
    if (p.containsKey('stock_quantity') && p['stock_quantity'] is int && p['stock_quantity'] < 0) throw ArgumentError('Stock cannot be negative');
    if (p.containsKey('moq') && p['moq'] is int && (p['moq'] < 1 || p['moq'] > 999)) throw ArgumentError('MOQ must be 1-999');
  }

  /// Create — mirrors Supabase `ProductRepository.create` / `AdminProductRepository.createProduct`
  static Future<({bool ok, String message, String? id})> create({
    required String productId,
    required String name,
    required double price,
    required String description,
    required String icon,
    required String category,
    required int stock,
    int moq = 1,
    String? image1,
    String? image2,
    String? image3,
  }) async {
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not initialized', id: null);
    try {
      final payload = _normalizeForWrite({
        'product_id': productId,
        'name': name,
        'price': price,
        'description': description,
        'icon': icon,
        'category': category,
        'stock_quantity': stock,
        'moq': moq,
        'image_url': image1,
        'image_2': image2,
        'image_3': image3,
      }, isCreate: true);
      _validate(payload, isCreate: true);
      try {
        final doc = await _withTimeout(
          AppwriteService.databases.createDocument(
            databaseId: _db,
            collectionId: _col,
            documentId: ID.unique(),
            data: payload,
          ),
          'createProduct',
        );
        return (ok: true, message: 'Product created', id: doc.$id);
      } on AppwriteException catch (e) {
        if (_isMissingAttributeError(e) && (_payloadHasExtraImages(payload) || _payloadHasMoq(payload))) {
          debugPrint('[AppwriteProducts] create fallback stripping image_2/3/moq due to: $e');
          final fallback = Map<String, dynamic>.from(payload)..remove('image_2')..remove('image_3')..remove('moq');
          try {
            final doc2 = await _withTimeout(
              AppwriteService.databases.createDocument(databaseId: _db, collectionId: _col, documentId: ID.unique(), data: fallback),
              'createProduct',
            );
            return (ok: true, message: 'Product created', id: doc2.$id);
          } catch (e2) {
            debugPrint('[AppwriteProducts] create fallback also failed: $e2');
          }
        }
        return (ok: false, message: _friendly(e), id: null);
      }
    } catch (e) {
      return (ok: false, message: e.toString(), id: null);
    }
  }

  /// Generic create from map (for admin page).
  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    if (!AppwriteService.isInitialized) throw Exception('Appwrite not configured.');
    final payload = _normalizeForWrite(productData, isCreate: true);
    _validate(payload, isCreate: true);
    try {
      final doc = await _withTimeout(
        AppwriteService.databases.createDocument(databaseId: _db, collectionId: _col, documentId: ID.unique(), data: payload),
        'createProduct',
      );
      return _docToMap(doc);
    } on AppwriteException catch (e) {
      if (_isMissingAttributeError(e) && (_payloadHasExtraImages(payload) || _payloadHasMoq(payload))) {
        debugPrint('[AppwriteProducts] createProduct fallback stripping image_2/3/moq due to: $e');
        final fallback = Map<String, dynamic>.from(payload)..remove('image_2')..remove('image_3')..remove('moq');
        try {
          final doc2 = await _withTimeout(
            AppwriteService.databases.createDocument(databaseId: _db, collectionId: _col, documentId: ID.unique(), data: fallback),
            'createProduct',
          );
          return _docToMap(doc2);
        } catch (e2) {
          debugPrint('[AppwriteProducts] createProduct fallback also failed: $e2');
        }
      }
      throw Exception(_friendly(e));
    }
  }

  /// Update — mirrors Supabase update
  static Future<({bool ok, String message})> update({
    required String id,
    required String productId,
    required String name,
    required double price,
    required String description,
    required String icon,
    required String category,
    required int stock,
    int moq = 1,
    String? image1,
    String? image2,
    String? image3,
  }) async {
    if (!AppwriteService.isInitialized) return (ok: false, message: 'Appwrite not initialized');
    try {
      final payload = _normalizeForWrite({
        'product_id': productId,
        'name': name,
        'price': price,
        'description': description,
        'icon': icon,
        'category': category,
        'stock_quantity': stock,
        'moq': moq,
        'image_url': image1,
        'image_2': image2,
        'image_3': image3,
      }, isCreate: false);
      if (payload.isEmpty) return (ok: false, message: 'No fields to update');
      try {
        await _withTimeout(
          AppwriteService.databases.updateDocument(databaseId: _db, collectionId: _col, documentId: id, data: payload),
          'updateProduct',
        );
        return (ok: true, message: 'Product updated');
      } on AppwriteException catch (e) {
        if (_isMissingAttributeError(e) && (_payloadHasExtraImages(payload) || _payloadHasMoq(payload))) {
          debugPrint('[AppwriteProducts] update fallback stripping image_2/3/moq due to: $e');
          final fallback = Map<String, dynamic>.from(payload)..remove('image_2')..remove('image_3')..remove('moq');
          // Also strip image_url if it's a clear (empty string) — attribute may not exist
          if (fallback['image_url'] is String && (fallback['image_url'] as String).isEmpty) fallback.remove('image_url');
          if (fallback.isNotEmpty) {
            try {
              await _withTimeout(
                AppwriteService.databases.updateDocument(databaseId: _db, collectionId: _col, documentId: id, data: fallback),
                'updateProduct',
              );
              return (ok: true, message: 'Product updated');
            } catch (e2) {
              debugPrint('[AppwriteProducts] update fallback also failed: $e2');
            }
          }
        }
        return (ok: false, message: _friendly(e));
      }
    } catch (e) {
      return (ok: false, message: e.toString());
    }
  }

  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    if (!AppwriteService.isInitialized) throw Exception('Appwrite not configured.');
    final payload = _normalizeForWrite(productData, isCreate: false);
    if (payload.isEmpty) throw ArgumentError('No fields to update');
    try {
      final doc = await _withTimeout(
        AppwriteService.databases.updateDocument(databaseId: _db, collectionId: _col, documentId: id.trim(), data: payload),
        'updateProduct',
      );
      return _docToMap(doc);
    } on AppwriteException catch (e) {
      if (_isMissingAttributeError(e) && (_payloadHasExtraImages(payload) || _payloadHasMoq(payload))) {
        debugPrint('[AppwriteProducts] updateProduct fallback stripping image_2/3/moq due to: $e — retrying without extra images');
        final fallback = Map<String, dynamic>.from(payload)..remove('image_2')..remove('image_3')..remove('moq');
        // Also strip image_url if it's a clear (empty string) — attribute may not exist
        if (fallback['image_url'] is String && (fallback['image_url'] as String).isEmpty) fallback.remove('image_url');
        if (fallback.isNotEmpty) {
          try {
            final doc2 = await _withTimeout(
              AppwriteService.databases.updateDocument(databaseId: _db, collectionId: _col, documentId: id.trim(), data: fallback),
              'updateProduct',
            );
            return _docToMap(doc2);
          } catch (e2) {
            debugPrint('[AppwriteProducts] updateProduct fallback also failed: $e2');
          }
        }
      }
      throw Exception(_friendly(e));
    }
  }

  static Future<bool> toggleActive(String id, bool isActive) async {
    try {
      await updateProduct(id, {'is_active': isActive});
      return true;
    } catch (e) {
      debugPrint('[AppwriteProducts] toggleActive failed: $e');
      return false;
    }
  }

  static Future<({bool ok, String message})> delete(String id) async {
    final ok = await deleteProduct(id);
    return (ok: ok, message: ok ? 'Product deleted' : 'Delete failed');
  }

  static Future<bool> deleteProduct(String id, {bool hardDelete = true, String? knownImageUrl}) async {
    if (!AppwriteService.isInitialized) throw Exception('Appwrite not configured.');
    final targetId = id.trim();
    if (targetId.isEmpty) throw ArgumentError('deleteProduct: id empty');
    // Best-effort: fetch image url if not provided (for storage cleanup)
    String? imageUrl = knownImageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      try {
        final row = await getProductById(targetId);
        imageUrl = row?['image_url']?.toString().trim();
        if (imageUrl != null && imageUrl.isEmpty) imageUrl = null;
      } catch (_) {}
    }
    try {
      if (!hardDelete) {
        try {
          await _withTimeout(
            AppwriteService.databases.updateDocument(databaseId: _db, collectionId: _col, documentId: targetId, data: {'is_active': false}),
            'soft delete',
          );
          return true;
        } catch (e) {
          debugPrint('[AppwriteProducts] soft-delete fallback to hard: $e');
        }
      }
      await _withTimeout(
        AppwriteService.databases.deleteDocument(databaseId: _db, collectionId: _col, documentId: targetId),
        'deleteProduct',
      );
      // Storage cleanup best-effort
      if (imageUrl != null) {
        final fileId = _extractFileId(imageUrl);
        if (fileId != null) {
          try {
            await AppwriteService.storage.deleteFile(bucketId: AppwriteConfig.bucketId, fileId: fileId);
          } catch (e) {
            debugPrint('[AppwriteProducts] storage remove skipped: $e');
          }
        }
      }
      return true;
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  static String? _extractFileId(String url) {
    // Appwrite storage URL pattern: .../storage/buckets/<bucket>/files/<fileId>/view
    final marker = '/files/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    var part = url.substring(idx + marker.length);
    final slash = part.indexOf('/');
    if (slash != -1) part = part.substring(0, slash);
    final q = part.indexOf('?');
    if (q != -1) part = part.substring(0, q);
    return part.isEmpty ? null : part;
  }

  // ── Storage ──
  static Future<String> uploadProductImage(Uint8List fileBytes, String fileName) async {
    if (!AppwriteService.isInitialized) throw Exception('Appwrite not configured.');
    if (fileBytes.isEmpty) throw ArgumentError('Image file is empty');
    if (fileBytes.lengthInBytes > 5 * 1024 * 1024) throw ArgumentError('Image must be <5MB');
    final sanitized = fileName.split(RegExp(r'[\\/]')).last.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final unique = '${DateTime.now().millisecondsSinceEpoch}_$sanitized';
    try {
      final file = await _withTimeout(
        AppwriteService.storage.createFile(
          bucketId: AppwriteConfig.bucketId,
          fileId: ID.unique(),
          file: InputFile.fromBytes(bytes: fileBytes, filename: unique),
        ),
        'uploadProductImage',
      );
      // Build preview URL — Appwrite getFileView
      final url = '${AppwriteConfig.endpoint}/storage/buckets/${AppwriteConfig.bucketId}/files/${file.$id}/view?project=${AppwriteConfig.projectId}';
      debugPrint('[AppwriteProducts] upload ok ${file.$id}');
      return url;
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  // ── Seed ──
  static Future<String> seedDemoProducts() async {
    if (!AppwriteService.isInitialized) return 'Appwrite not initialized';
    const demo = [
      {'product_id': '01', 'name': 'Chocolaty Gud 700g', 'price': 299.0, 'description': '100% Natural • Unrefined • No Added Ingredients – Premium chocolaty jaggery chunks in glass jar by Hari Om Traders', 'icon': 'grain', 'category': 'Powder', 'stock_quantity': 300, 'moq': 2, 'image_url': 'assets/img/products/gud_700g.png', 'is_active': true},
      {'product_id': '02', 'name': 'Organic Jaggery Cubes 1kg', 'price': 229.0, 'description': 'Traditional hand-cut cubes, rich iron & minerals', 'icon': 'spa', 'category': 'Cubes', 'stock_quantity': 250, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-cubes-1kg.png', 'is_active': true},
      {'product_id': '03', 'name': 'Organic Liquid Jaggery Kakvi 500ml', 'price': 349.0, 'description': 'Thick liquid jaggery (kakvi) – natural sweetener for tea & desserts', 'icon': 'water_drop', 'category': 'Liquid', 'stock_quantity': 180, 'moq': 2, 'image_url': 'assets/img/products/organic-liquid-jaggery-kakvi-500ml.jpg', 'is_active': true},
      {'product_id': '04', 'name': 'Organic Jaggery with Ginger 250g', 'price': 249.0, 'description': 'Infused with sun-dried ginger – warming & digestive', 'icon': 'eco', 'category': 'Flavored', 'stock_quantity': 200, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-ginger-250g.png', 'is_active': true},
      {'product_id': '05', 'name': 'Organic Jaggery with Moringa 250g', 'price': 279.0, 'description': 'Enriched with moringa leaf powder – superfood blend', 'icon': 'local_florist', 'category': 'Flavored', 'stock_quantity': 150, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-moringa-250g.jpg', 'is_active': true},
      {'product_id': '06', 'name': 'Organic Jaggery with Turmeric 250g', 'price': 269.0, 'description': 'Golden turmeric blend – immunity boosting', 'icon': 'spa', 'category': 'Flavored', 'stock_quantity': 170, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-turmeric-250g.png', 'is_active': true},
      {'product_id': '07', 'name': 'Organic Jaggery Block 1kg', 'price': 249.0, 'description': 'Traditional solid block – directly from wood-pressed cane juice', 'icon': 'square', 'category': 'Block', 'stock_quantity': 220, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-block-1kg.png', 'is_active': true},
      {'product_id': '08', 'name': 'Organic Granular Jaggery 1kg', 'price': 229.0, 'description': 'Free-flowing granular – easy to spoon & dissolve', 'icon': 'grain', 'category': 'Granular', 'stock_quantity': 260, 'moq': 2, 'image_url': 'assets/img/products/organic-granular-jaggery-1kg.png', 'is_active': true},
      {'product_id': '09', 'name': 'Organic Jaggery Peanut Chikki 200g', 'price': 179.0, 'description': 'Crunchy peanut brittle bound with organic jaggery', 'icon': 'cookie', 'category': 'Chikki', 'stock_quantity': 400, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-peanut-chikki-200g.png', 'is_active': true},
      {'product_id': '10', 'name': 'Organic Jaggery Sesame Chikki 200g', 'price': 189.0, 'description': 'Roasted sesame & jaggery – calcium rich', 'icon': 'cookie', 'category': 'Chikki', 'stock_quantity': 380, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-sesame-chikki-200g.jpg', 'is_active': true},
      {'product_id': '11', 'name': 'Organic Jaggery Coconut Chikki 200g', 'price': 199.0, 'description': 'Coconut flakes with jaggery – tropical treat', 'icon': 'cookie', 'category': 'Chikki', 'stock_quantity': 350, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-coconut-chikki-200g.png', 'is_active': true},
      {'product_id': '12', 'name': 'Organic Jaggery Tea Blend 100g', 'price': 299.0, 'description': 'Jaggery powder blended for chai – dissolves instantly', 'icon': 'local_cafe', 'category': 'Blend', 'stock_quantity': 300, 'moq': 1, 'image_url': 'assets/img/products/organic-jaggery-tea-blend-100g.jpg', 'is_active': true},
      {'product_id': '13', 'name': 'Organic Jaggery Syrup 500ml', 'price': 329.0, 'description': 'Pourable syrup – perfect for pancakes & porridge', 'icon': 'water_drop', 'category': 'Syrup', 'stock_quantity': 160, 'moq': 1, 'image_url': 'assets/img/products/organic-jaggery-syrup-500ml.png', 'is_active': true},
      {'product_id': '14', 'name': 'Organic Jaggery with Cardamom 250g', 'price': 289.0, 'description': 'Aromatic cardamom infusion – premium aroma', 'icon': 'eco', 'category': 'Flavored', 'stock_quantity': 140, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-cardamom-250g.png', 'is_active': true},
      {'product_id': '15', 'name': 'Organic Jaggery Gift Hamper 1.5kg', 'price': 899.0, 'description': 'Assorted hamper – powder, cubes, chikkis & syrup – festive gift', 'icon': 'card_giftcard', 'category': 'Hamper', 'stock_quantity': 90, 'moq': 1, 'image_url': 'assets/img/products/organic-jaggery-gift-hamper-1-5kg.jpg', 'is_active': true},
    ];
    int inserted = 0;
    for (final p in demo) {
      try {
        await AppwriteService.databases.createDocument(databaseId: _db, collectionId: _col, documentId: ID.unique(), data: Map<String, dynamic>.from(p));
        inserted++;
      } catch (e) {
        debugPrint('[AppwriteProducts] seed skip ${p['name']}: $e');
      }
    }
    return 'Seeded $inserted / ${demo.length} jaggery products';
  }

  // ── Compat helpers for existing UI (imageUrlOf etc.) ──
  static String? imageUrlOf(Map<String, dynamic> row) {
    for (final k in ['image_url', 'imageUrl', 'image']) {
      final v = row[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static String? imageUrlOf2(Map<String, dynamic> row) {
    for (final k in ['image_2', 'image2', 'image_url_2']) {
      final v = row[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static String? imageUrlOf3(Map<String, dynamic> row) {
    for (final k in ['image_3', 'image3', 'image_url_3']) {
      final v = row[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static List<String> allImageUrlsOf(Map<String, dynamic> row) {
    final list = <String>[];
    final a = imageUrlOf(row);
    final b = imageUrlOf2(row);
    final c = imageUrlOf3(row);
    if (a != null) list.add(a);
    if (b != null) list.add(b);
    if (c != null) list.add(c);
    return list;
  }

  static int stockOf(Map<String, dynamic> row) {
    for (final k in ['stock_quantity', 'stockQuantity', 'stock']) {
      final v = row[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v != null) {
        final p = int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9\-]'), ''));
        if (p != null) return p;
      }
    }
    return 0;
  }

  static int moqOf(Map<String, dynamic> row) {
    for (final k in ['moq', 'minimum_order_quantity', 'min_order_quantity', 'min_qty']) {
      final v = row[k];
      if (v is int) return v.clamp(1, 999);
      if (v is num) return v.toInt().clamp(1, 999);
      if (v != null) {
        final p = int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9\-]'), ''));
        if (p != null) return p.clamp(1, 999);
      }
    }
    return 2;
  }

  static bool isActiveOf(Map<String, dynamic> row) {
    if (row.containsKey('is_active')) {
      final v = row['is_active'];
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
    }
    return true;
  }
}
