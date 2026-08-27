import '../entities/product_entity.dart';

abstract class CatalogRepository {
  Future<List<ProductEntity>> getProducts({int page = 1, int limit = 20, String? query, String? category, String? sort, double? minPrice, double? maxPrice, bool? inStock, double? minRating});
  Future<ProductEntity> getProduct(String id);
  Future<int> getTotalCount({String? query, String? category});
}
