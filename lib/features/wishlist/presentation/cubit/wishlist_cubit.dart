import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../catalog/domain/entities/product_entity.dart';
import '../../../catalog/data/datasources/catalog_remote_datasource.dart';

class WishlistState extends Equatable {
  const WishlistState({this.items = const [], this.status = WishlistStatus.initial});
  final List<ProductEntity> items;
  final WishlistStatus status;
  int get count => items.length;
  WishlistState copyWith({List<ProductEntity>? items, WishlistStatus? status}) => WishlistState(items: items ?? this.items, status: status ?? this.status);
  @override
  List<Object?> get props => [items, status];
}

enum WishlistStatus { initial, loading, success }

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit() : super(const WishlistState());

  static final Set<String> _ids = {'1', '3', '7'};

  Future<void> load() async {
    emit(state.copyWith(status: WishlistStatus.loading));
    try {
      final ds = CatalogMockDataSource();
      final all = await ds.getProducts(limit: 100);
      final items = all.where((p) => _ids.contains(p.id)).toList();
      emit(state.copyWith(items: items, status: WishlistStatus.success));
    } catch (_) {
      emit(state.copyWith(status: WishlistStatus.success));
    }
  }

  void toggle(ProductEntity product) {
    final list = List<ProductEntity>.from(state.items);
    final idx = list.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _ids.remove(product.id);
      list.removeAt(idx);
    } else {
      _ids.add(product.id);
      list.add(product);
    }
    emit(state.copyWith(items: list));
  }

  bool isWishlisted(String id) => _ids.contains(id);

  void moveToCart(String id) {
    _ids.remove(id);
    emit(state.copyWith(items: state.items.where((p) => p.id != id).toList()));
  }
}
