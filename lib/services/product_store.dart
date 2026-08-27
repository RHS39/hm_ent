import 'package:flutter/material.dart';
import '../appwrite/product_repository.dart';
import '../appwrite/appwrite_client.dart';

/// Global product store — single source of truth for all product data.
/// Any CRUD in admin immediately propagates to all listeners (products page, detail, etc.)
class ProductStore extends ChangeNotifier {
  ProductStore._();
  static final ProductStore instance = ProductStore._();

  List<Map<String, dynamic>> _products = [];
  bool _loading = false;
  bool _loaded = false;

  List<Map<String, dynamic>> get products => _products;
  bool get loading => _loading;
  bool get loaded => _loaded;

  bool get _isOffline => !AppwriteService.isInitialized;

  List<Map<String, dynamic>> _demoRows() => [
        {'id': '1', '\$id': '1', 'product_id': '01', 'name': 'Chocolaty Gud 700g', 'price': 299.0, 'description': '100% Natural • Unrefined • No Added Ingredients – Premium chocolaty jaggery chunks in glass jar by Hari Om Traders', 'icon': 'grain', 'category': 'Powder', 'stock_quantity': 300, 'moq': 2, 'image_url': 'assets/img/products/gud_700g.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '2', '\$id': '2', 'product_id': '02', 'name': 'Organic Jaggery Cubes 1kg', 'price': 229.0, 'description': 'Traditional hand-cut cubes, rich iron & minerals', 'icon': 'spa', 'category': 'Cubes', 'stock_quantity': 250, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-cubes-1kg.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '3', '\$id': '3', 'product_id': '03', 'name': 'Organic Liquid Jaggery Kakvi 500ml', 'price': 349.0, 'description': 'Thick liquid jaggery (kakvi) – natural sweetener for tea & desserts', 'icon': 'water_drop', 'category': 'Liquid', 'stock_quantity': 180, 'moq': 2, 'image_url': 'assets/img/products/organic-liquid-jaggery-kakvi-500ml.jpg', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '4', '\$id': '4', 'product_id': '04', 'name': 'Organic Jaggery with Ginger 250g', 'price': 249.0, 'description': 'Infused with sun-dried ginger – warming & digestive', 'icon': 'eco', 'category': 'Flavored', 'stock_quantity': 200, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-ginger-250g.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '5', '\$id': '5', 'product_id': '05', 'name': 'Organic Jaggery with Moringa 250g', 'price': 279.0, 'description': 'Enriched with moringa leaf powder – superfood blend', 'icon': 'local_florist', 'category': 'Flavored', 'stock_quantity': 150, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-moringa-250g.jpg', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '6', '\$id': '6', 'product_id': '06', 'name': 'Organic Jaggery with Turmeric 250g', 'price': 269.0, 'description': 'Golden turmeric blend – immunity boosting', 'icon': 'spa', 'category': 'Flavored', 'stock_quantity': 170, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-turmeric-250g.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '7', '\$id': '7', 'product_id': '07', 'name': 'Organic Jaggery Block 1kg', 'price': 249.0, 'description': 'Traditional solid block – directly from wood-pressed cane juice', 'icon': 'square', 'category': 'Block', 'stock_quantity': 220, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-block-1kg.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '8', '\$id': '8', 'product_id': '08', 'name': 'Organic Granular Jaggery 1kg', 'price': 229.0, 'description': 'Free-flowing granular – easy to spoon & dissolve', 'icon': 'grain', 'category': 'Granular', 'stock_quantity': 260, 'moq': 2, 'image_url': 'assets/img/products/organic-granular-jaggery-1kg.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '9', '\$id': '9', 'product_id': '09', 'name': 'Organic Jaggery Peanut Chikki 200g', 'price': 179.0, 'description': 'Crunchy peanut brittle bound with organic jaggery', 'icon': 'cookie', 'category': 'Chikki', 'stock_quantity': 400, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-peanut-chikki-200g.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '10', '\$id': '10', 'product_id': '10', 'name': 'Organic Jaggery Sesame Chikki 200g', 'price': 189.0, 'description': 'Roasted sesame & jaggery – calcium rich', 'icon': 'cookie', 'category': 'Chikki', 'stock_quantity': 380, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-sesame-chikki-200g.jpg', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '11', '\$id': '11', 'product_id': '11', 'name': 'Organic Jaggery Coconut Chikki 200g', 'price': 199.0, 'description': 'Coconut flakes with jaggery – tropical treat', 'icon': 'cookie', 'category': 'Chikki', 'stock_quantity': 350, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-coconut-chikki-200g.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '12', '\$id': '12', 'product_id': '12', 'name': 'Organic Jaggery Tea Blend 100g', 'price': 299.0, 'description': 'Jaggery powder blended for chai – dissolves instantly', 'icon': 'local_cafe', 'category': 'Blend', 'stock_quantity': 300, 'moq': 1, 'image_url': 'assets/img/products/organic-jaggery-tea-blend-100g.jpg', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '13', '\$id': '13', 'product_id': '13', 'name': 'Organic Jaggery Syrup 500ml', 'price': 329.0, 'description': 'Pourable syrup – perfect for pancakes & porridge', 'icon': 'water_drop', 'category': 'Syrup', 'stock_quantity': 160, 'moq': 1, 'image_url': 'assets/img/products/organic-jaggery-syrup-500ml.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '14', '\$id': '14', 'product_id': '14', 'name': 'Organic Jaggery with Cardamom 250g', 'price': 289.0, 'description': 'Aromatic cardamom infusion – premium aroma', 'icon': 'eco', 'category': 'Flavored', 'stock_quantity': 140, 'moq': 2, 'image_url': 'assets/img/products/organic-jaggery-cardamom-250g.png', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
        {'id': '15', '\$id': '15', 'product_id': '15', 'name': 'Organic Jaggery Gift Hamper 1.5kg', 'price': 899.0, 'description': 'Assorted hamper – powder, cubes, chikkis & syrup – festive gift', 'icon': 'card_giftcard', 'category': 'Hamper', 'stock_quantity': 90, 'moq': 1, 'image_url': 'assets/img/products/organic-jaggery-gift-hamper-1-5kg.jpg', 'is_active': true, 'created_at': DateTime.now().toIso8601String()},
      ];

  /// Fetch all products from Appwrite and notify listeners.
  /// Falls back to local cache/demo data for demo/offline mode.
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final fetched = await AppwriteProductRepository.fetchProducts();
      if (fetched.isNotEmpty) {
        _products = fetched;
      } else if (_isOffline && _products.isEmpty) {
        _products = _demoRows();
      } else if (fetched.isNotEmpty || _products.isEmpty) {
        _products = fetched;
      }
      _loaded = true;
    } catch (e) {
      debugPrint('[ProductStore] load failed: $e');
      if (_isOffline && _products.isEmpty) {
        _products = _demoRows();
        _loaded = true;
      }
    }
    _loading = false;
    notifyListeners();
  }

  /// Refresh — force re-fetch even if already loaded. Used by admin CRUD to guarantee sync.
  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final fetched = await AppwriteProductRepository.fetchProducts();
      if (fetched.isNotEmpty) {
        _products = fetched;
      } else if (_isOffline) {
        // keep local demo data, don't wipe
      } else if (_products.isEmpty) {
        _products = fetched;
      }
      _loaded = true;
    } catch (e) {
      debugPrint('[ProductStore] refresh failed: $e');
      // Demo/offline: keep local cache, don't wipe
    }
    _loading = false;
    notifyListeners();
  }

  /// Explicit sync — always fetches fresh from Appwrite regardless of loaded state.
  Future<void> sync() async => refresh();

  /// Ensure demo data exists when in demo/offline mode and cache is empty.
  void ensureDemoSeed() {
    if (_products.isEmpty && _isOffline) {
      _products = _demoRows();
      _loaded = true;
      notifyListeners();
    }
  }

  /// Replace local cache with externally fetched data (used by admin after direct fetch).
  void replaceAll(List<Map<String, dynamic>> rows) {
    _products = rows;
    _loaded = true;
    notifyListeners();
  }

  /// Create product — syncs with Appwrite, falls back to local for demo/offline.
  Future<({bool ok, String message, String? id})> create({
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
    try {
      final res = await AppwriteProductRepository.create(
        productId: productId,
        name: name,
        price: price,
        description: description,
        icon: icon,
        category: category,
        stock: stock,
        moq: moq,
        image1: image1,
        image2: image2,
        image3: image3,
      );
      if (res.ok) {
        await refresh();
        return res;
      }
      if (_isOffline) {
        // fall through to local
      } else {
        return res;
      }
    } catch (e) {
      debugPrint('[ProductStore] create remote failed: $e');
      if (!_isOffline && _isAuthError(e)) rethrow;
    }
    // Demo/offline fallback: mutate local cache
    final newId = 'demo-${DateTime.now().millisecondsSinceEpoch}';
    final row = <String, dynamic>{
      'id': newId,
      '\$id': newId,
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
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };
    _products = [row, ..._products];
    _loaded = true;
    notifyListeners();
    return (ok: true, message: 'Product created (demo mode)', id: newId);
  }

  bool _isAuthError(dynamic e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('401') || msg.contains('403') || msg.contains('session expired') || msg.contains('not authenticated') || msg.contains('jwt') || msg.contains('unauthorized');
  }

  /// Update product — syncs with Appwrite, falls back to local for demo/offline.
  Future<({bool ok, String message})> update({
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
    try {
      final res = await AppwriteProductRepository.update(
        id: id,
        productId: productId,
        name: name,
        price: price,
        description: description,
        icon: icon,
        category: category,
        stock: stock,
        moq: moq,
        image1: image1,
        image2: image2,
        image3: image3,
      );
      if (res.ok) {
        await refresh();
        return res;
      }
      if (!_isOffline) return res;
    } catch (e) {
      debugPrint('[ProductStore] update remote failed: $e');
      if (!_isOffline && _isAuthError(e)) rethrow;
    }
    // Demo/offline fallback: mutate local cache — preserve existing images when null/empty
    final idx = _products.indexWhere((p) => p['id'].toString() == id || p['\$id'].toString() == id);
    if (idx != -1) {
      final existing = _products[idx];
      final updated = <String, dynamic>{
        ...existing,
        'product_id': productId,
        'name': name,
        'price': price,
        'description': description,
        'icon': icon,
        'category': category,
        'stock_quantity': stock,
        'moq': moq,
      };
      // Only overwrite image fields when a non-empty value is provided.
      // This preserves existing images when the update payload omits them
      // and allows multi-image updates when multiple slots are selected.
      if (image1 != null && image1.trim().isNotEmpty) {
        updated['image_url'] = image1.trim();
      }
      if (image2 != null && image2.trim().isNotEmpty) {
        updated['image_2'] = image2.trim();
      } else if (image2 == null) {
        // keep existing image_2 — do not clear on null (mirrors Appwrite omit)
      }
      if (image3 != null && image3.trim().isNotEmpty) {
        updated['image_3'] = image3.trim();
      }
      // Explicit clear: if caller passes empty string, remove the key
      if (image2 != null && image2.trim().isEmpty) updated.remove('image_2');
      if (image3 != null && image3.trim().isEmpty) updated.remove('image_3');
      if (image1 != null && image1.trim().isEmpty) updated.remove('image_url');
      _products[idx] = updated;
      notifyListeners();
      return (ok: true, message: 'Product updated (demo mode)');
    }
    return (ok: false, message: 'Product not found locally');
  }

  /// Delete product — syncs with Appwrite, falls back to local for demo/offline.
  Future<({bool ok, String message})> delete(String id) async {
    try {
      final res = await AppwriteProductRepository.delete(id);
      if (res.ok) {
        await refresh();
        return res;
      }
      if (!_isOffline) return res;
    } catch (e) {
      debugPrint('[ProductStore] delete remote failed: $e');
      if (!_isOffline && _isAuthError(e)) rethrow;
    }
    final before = _products.length;
    _products.removeWhere((p) => p['id'].toString() == id || p['\$id'].toString() == id);
    if (_products.length < before) {
      notifyListeners();
      return (ok: true, message: 'Product deleted (demo mode)');
    }
    return (ok: false, message: 'Product not found locally');
  }

  /// Find product by ID from local cache.
  Map<String, dynamic>? findById(String id) {
    try {
      return _products.firstWhere((p) => p['id'].toString() == id);
    } catch (_) {
      return null;
    }
  }

  /// Find product by name from local cache.
  Map<String, dynamic>? findByName(String name) {
    try {
      return _products.firstWhere((p) => (p['name'] ?? '') == name);
    } catch (_) {
      return null;
    }
  }
}
