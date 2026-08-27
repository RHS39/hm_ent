import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/catalog_repository.dart';

class GetProductsParams {
  const GetProductsParams({this.page = 1, this.limit = 20, this.query, this.category, this.sort, this.minPrice, this.maxPrice, this.inStock, this.minRating});
  final int page;
  final int limit;
  final String? query;
  final String? category;
  final String? sort;
  final double? minPrice;
  final double? maxPrice;
  final bool? inStock;
  final double? minRating;
}

class GetProducts implements UseCase<List<ProductEntity>, GetProductsParams> {
  GetProducts(this.repo);
  final CatalogRepository repo;
  @override
  Future<List<ProductEntity>> call(GetProductsParams params) => repo.getProducts(page: params.page, limit: params.limit, query: params.query, category: params.category, sort: params.sort, minPrice: params.minPrice, maxPrice: params.maxPrice, inStock: params.inStock, minRating: params.minRating);
}

class GetProductDetail implements UseCase<ProductEntity, String> {
  GetProductDetail(this.repo);
  final CatalogRepository repo;
  @override
  Future<ProductEntity> call(String params) => repo.getProduct(params);
}
