import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../catalog/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item.dart';

class CartState extends Equatable {
  const CartState({this.items = const [], this.promoCode, this.discount = 0, this.isPromoValid});
  final List<CartItemEntity> items;
  final String? promoCode;
  final double discount;
  final bool? isPromoValid;

  int get count => items.fold(0, (s, e) => s + e.quantity);
  double get subtotal => items.fold(0, (s, e) => s + e.total);
  double get tax => subtotal * 0.05;
  double get shipping => subtotal >= 499 || subtotal == 0 ? 0 : 49;
  double get savings => items.fold(0.0, (s, e) => s + ((e.product.price - e.price) * e.quantity)) + discount;
  double get total => (subtotal + tax + shipping - discount).clamp(0, double.infinity);

  CartState copyWith({List<CartItemEntity>? items, String? promoCode, double? discount, bool? isPromoValid}) => CartState(items: items ?? this.items, promoCode: promoCode ?? this.promoCode, discount: discount ?? this.discount, isPromoValid: isPromoValid ?? this.isPromoValid);
  @override
  List<Object?> get props => [items, promoCode, discount, isPromoValid];
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void add(ProductEntity product, {int qty = 1, String? variant, double? price}) {
    final list = List<CartItemEntity>.from(state.items);
    final key = '${product.id}::$variant';
    final idx = list.indexWhere((e) => '${e.product.id}::${e.variantLabel}' == key);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(quantity: list[idx].quantity + qty);
    } else {
      list.add(CartItemEntity(product: product, quantity: qty, variantLabel: variant, unitPrice: price));
    }
    emit(state.copyWith(items: list));
  }

  void removeAt(int index) {
    final list = List<CartItemEntity>.from(state.items)..removeAt(index);
    emit(state.copyWith(items: list));
  }

  void setQty(int index, int qty) {
    if (qty <= 0) { removeAt(index); return; }
    final list = List<CartItemEntity>.from(state.items);
    list[index] = list[index].copyWith(quantity: qty);
    emit(state.copyWith(items: list));
  }

  void clear() => emit(const CartState());

  void applyPromo(String code) {
    final c = code.trim().toUpperCase();
    if (c == 'JAGGERY10') {
      emit(state.copyWith(promoCode: c, discount: state.subtotal * 0.10, isPromoValid: true));
    } else if (c == 'FREESHIP') {
      emit(state.copyWith(promoCode: c, discount: state.shipping, isPromoValid: true));
    } else if (c.isEmpty) {
      emit(state.copyWith(promoCode: null, discount: 0, isPromoValid: null));
    } else {
      emit(state.copyWith(isPromoValid: false));
    }
  }

  void removePromo() => emit(state.copyWith(promoCode: null, discount: 0, isPromoValid: null));
}
