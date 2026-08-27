import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_products.dart';

enum DetailStatus { initial, loading, success, failure }

class ProductDetailState extends Equatable {
  const ProductDetailState({this.status = DetailStatus.initial, this.product, this.selectedVariant = 0, this.quantity = 1, this.error});
  final DetailStatus status;
  final ProductEntity? product;
  final int selectedVariant;
  final int quantity;
  final String? error;
  ProductDetailState copyWith({DetailStatus? status, ProductEntity? product, int? selectedVariant, int? quantity, String? error}) => ProductDetailState(status: status ?? this.status, product: product ?? this.product, selectedVariant: selectedVariant ?? this.selectedVariant, quantity: quantity ?? this.quantity, error: error);
  @override
  List<Object?> get props => [status, product, selectedVariant, quantity, error];
}

class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit(this.getDetail) : super(const ProductDetailState());
  final GetProductDetail getDetail;

  Future<void> load(String id) async {
    emit(state.copyWith(status: DetailStatus.loading));
    try {
      final p = await getDetail(id);
      emit(state.copyWith(status: DetailStatus.success, product: p, quantity: 2));
    } catch (e) {
      emit(state.copyWith(status: DetailStatus.failure, error: e.toString()));
    }
  }

  void selectVariant(int i) => emit(state.copyWith(selectedVariant: i));
  void setQty(int q) => emit(state.copyWith(quantity: q.clamp(1, 99)));
}
