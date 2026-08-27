import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    this.salePrice,
    this.description = '',
    this.category = 'Other',
    this.rating = 4.5,
    this.reviewsCount = 0,
    this.stock = 100,
    this.isInStock = true,
    this.images = const [],
    this.iconName = 'spa',
    this.badge,
    this.isWishlisted = false,
  });

  final String id;
  final String name;
  final double price;
  final double? salePrice;
  final String description;
  final String category;
  final double rating;
  final int reviewsCount;
  final int stock;
  final bool isInStock;
  final List<String> images;
  final String iconName;
  final String? badge;
  final bool isWishlisted;

  double get effectivePrice => salePrice ?? price;
  double get discountPercent => salePrice == null || salePrice! >= price ? 0 : ((price - salePrice!) / price * 100);
  bool get onSale => salePrice != null && salePrice! < price;

  ProductEntity copyWith({bool? isWishlisted, double? salePrice}) => ProductEntity(
        id: id,
        name: name,
        price: price,
        salePrice: salePrice ?? this.salePrice,
        description: description,
        category: category,
        rating: rating,
        reviewsCount: reviewsCount,
        stock: stock,
        isInStock: isInStock,
        images: images,
        iconName: iconName,
        badge: badge,
        isWishlisted: isWishlisted ?? this.isWishlisted,
      );

  @override
  List<Object?> get props => [id, name, price, salePrice, category, rating, stock];
}
