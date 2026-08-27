import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_products.dart';

enum CatalogStatus { initial, loading, success, failure, loadingMore }

class CatalogState extends Equatable {
  const CatalogState({
    this.status = CatalogStatus.initial,
    this.products = const [],
    this.hasReachedMax = false,
    this.page = 1,
    this.query = '',
    this.category = 'All',
    this.sort = 'Featured',
    this.minPrice,
    this.maxPrice,
    this.inStock,
    this.minRating,
    this.error,
  });
  final CatalogStatus status;
  final List<ProductEntity> products;
  final bool hasReachedMax;
  final int page;
  final String query;
  final String category;
  final String sort;
  final double? minPrice;
  final double? maxPrice;
  final bool? inStock;
  final double? minRating;
  final String? error;

  CatalogState copyWith({CatalogStatus? status, List<ProductEntity>? products, bool? hasReachedMax, int? page, String? query, String? category, String? sort, double? minPrice, double? maxPrice, bool? inStock, double? minRating, String? error}) => CatalogState(
        status: status ?? this.status,
        products: products ?? this.products,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        page: page ?? this.page,
        query: query ?? this.query,
        category: category ?? this.category,
        sort: sort ?? this.sort,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        inStock: inStock ?? this.inStock,
        minRating: minRating ?? this.minRating,
        error: error,
      );

  @override
  List<Object?> get props => [status, products, hasReachedMax, page, query, category, sort, minPrice, maxPrice, inStock, minRating, error];
}

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this.getProducts) : super(const CatalogState());
  final GetProducts getProducts;

  Future<void> fetchInitial() async {
    emit(state.copyWith(status: CatalogStatus.loading, page: 1, hasReachedMax: false));
    try {
      final items = await getProducts(GetProductsParams(page: 1, limit: 20, query: state.query, category: state.category, sort: state.sort, minPrice: state.minPrice, maxPrice: state.maxPrice, inStock: state.inStock, minRating: state.minRating));
      emit(state.copyWith(status: CatalogStatus.success, products: items, hasReachedMax: items.length < 20, page: 1));
    } catch (e) {
      emit(state.copyWith(status: CatalogStatus.failure, error: e.toString()));
    }
  }

  Future<void> fetchMore() async {
    if (state.hasReachedMax || state.status == CatalogStatus.loadingMore) return;
    emit(state.copyWith(status: CatalogStatus.loadingMore));
    try {
      final nextPage = state.page + 1;
      final items = await getProducts(GetProductsParams(page: nextPage, limit: 20, query: state.query, category: state.category, sort: state.sort, minPrice: state.minPrice, maxPrice: state.maxPrice, inStock: state.inStock, minRating: state.minRating));
      emit(state.copyWith(status: CatalogStatus.success, products: [...state.products, ...items], hasReachedMax: items.length < 20, page: nextPage));
    } catch (e) {
      emit(state.copyWith(status: CatalogStatus.failure, error: e.toString()));
    }
  }

  void updateQuery(String q) {
    emit(state.copyWith(query: q, page: 1));
    fetchInitial();
  }

  void updateCategory(String c) {
    emit(state.copyWith(category: c, page: 1));
    fetchInitial();
  }

  void updateSort(String s) {
    emit(state.copyWith(sort: s, page: 1));
    fetchInitial();
  }

  void applyFilters({double? minPrice, double? maxPrice, bool? inStock, double? minRating}) {
    emit(state.copyWith(minPrice: minPrice, maxPrice: maxPrice, inStock: inStock, minRating: minRating, page: 1));
    fetchInitial();
  }

  void clearFilters() {
    emit(state.copyWith(minPrice: null, maxPrice: null, inStock: null, minRating: null, category: 'All', page: 1));
    fetchInitial();
  }
}
