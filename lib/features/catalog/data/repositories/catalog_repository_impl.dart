import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this.remote);
  final CatalogRemoteDataSource remote;

  @override
  Future<List<ProductEntity>> getProducts({int page = 1, int limit = 20, String? query, String? category, String? sort, double? minPrice, double? maxPrice, bool? inStock, double? minRating}) async {
    final offset = (page - 1) * limit;
    return remote.getProducts(limit: limit, offset: offset, query: query, category: category, sort: sort, minPrice: minPrice, maxPrice: maxPrice, inStock: inStock, minRating: minRating);
  }

  @override
  Future<ProductEntity> getProduct(String id) => remote.getProductById(id);

  @override
  Future<int> getTotalCount({String? query, String? category}) async {
    final all = await remote.getProducts(limit: 1000, offset: 0, query: query, category: category);
    return all.length;
  }
}
