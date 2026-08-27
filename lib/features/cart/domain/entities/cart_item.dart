import 'package:equatable/equatable.dart';
import '../../../catalog/domain/entities/product_entity.dart';

class CartItemEntity extends Equatable {
  const CartItemEntity({required this.product, required this.quantity, this.variantLabel, this.unitPrice});
  final ProductEntity product;
  final int quantity;
  final String? variantLabel;
  final double? unitPrice;
  double get price => unitPrice ?? product.effectivePrice;
  double get total => price * quantity;
  CartItemEntity copyWith({int? quantity}) => CartItemEntity(product: product, quantity: quantity ?? this.quantity, variantLabel: variantLabel, unitPrice: unitPrice);
  @override
  List<Object?> get props => [product.id, variantLabel, quantity];
}
