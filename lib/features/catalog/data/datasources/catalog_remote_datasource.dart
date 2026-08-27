import '../../../../services/product_store.dart';
import '../models/product_model.dart';

abstract class CatalogRemoteDataSource {
  Future<List<ProductModel>> getProducts({int limit = 20, int offset = 0, String? query, String? category, String? sort, double? minPrice, double? maxPrice, bool? inStock, double? minRating});
  Future<ProductModel> getProductById(String id);
}

class CatalogMockDataSource implements CatalogRemoteDataSource {
  @override
  Future<List<ProductModel>> getProducts({int limit = 20, int offset = 0, String? query, String? category, String? sort, double? minPrice, double? maxPrice, bool? inStock, double? minRating}) async {
    await Future.delayed(const Duration(milliseconds: 350));
    await ProductStore.instance.load();
    var list = ProductStore.instance.products.map((m) => ProductModel.fromMap(m)).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q) || p.category.toLowerCase().contains(q)).toList();
    }
    if (category != null && category != 'All') {
      list = list.where((p) => _matchCategory(p.category, category) || p.category == category).toList();
    }
    if (minPrice != null) list = list.where((p) => p.effectivePrice >= minPrice).toList();
    if (maxPrice != null) list = list.where((p) => p.effectivePrice <= maxPrice).toList();
    if (inStock == true) list = list.where((p) => p.isInStock).toList();
    if (minRating != null) list = list.where((p) => p.rating >= minRating).toList();

    switch (sort) {
      case 'Price: Low to High':
        list.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'Popularity':
        list.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
        break;
      case 'Newest':
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        break;
    }
    final total = list.length;
    if (offset >= total) return [];
    final end = (offset + limit).clamp(0, total);
    return list.sublist(offset, end);
  }

  bool _matchCategory(String productCat, String filter) {
    final n = productCat.toLowerCase();
    switch (filter) {
      case 'Pouches':
        return n.contains('powder') || n.contains('granular') || n.contains('pouches');
      case 'Chikki':
        return n.contains('chikki');
      case 'Syrup & Kakvi':
        return n.contains('syrup') || n.contains('kakvi') || n.contains('liquid');
      case 'Blocks':
        return n.contains('block') || n.contains('cubes');
      case 'Spiced':
        return n.contains('flavored') || n.contains('ginger') || n.contains('tea');
      case 'Gifting':
        return n.contains('hamper');
      default:
        return false;
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    await ProductStore.instance.load();
    final m = ProductStore.instance.products.firstWhere((e) => '${e['id']}' == id, orElse: () => throw Exception('Product not found'));
    return ProductModel.fromMap(m);
  }
}
