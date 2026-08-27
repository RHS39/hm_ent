import '../../domain/entities/product_entity.dart';
import 'package:flutter/material.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    super.salePrice,
    super.description,
    super.category,
    super.rating,
    super.reviewsCount,
    super.stock,
    super.isInStock,
    super.images,
    super.iconName,
    super.badge,
  });

  factory ProductModel.fromMap(Map<String, dynamic> m) {
    final price = m['price'] is num ? (m['price'] as num).toDouble() : double.tryParse('${m['price']}') ?? 0;
    final sale = m['sale_price'] is num ? (m['sale_price'] as num).toDouble() : null;
    final stockQ = m['stock_quantity'] is int ? m['stock_quantity'] as int : int.tryParse('${m['stock_quantity'] ?? m['stock'] ?? 100}') ?? 100;
    final imgs = <String>[];
    for (final k in ['image_url', 'image', 'image_1', 'image_2', 'image_3']) {
      final v = m[k]?.toString().trim();
      if (v != null && v.isNotEmpty) imgs.add(v);
    }
    final rating = (m['rating'] is num ? (m['rating'] as num).toDouble() : 4.0 + (m['id'].hashCode % 10) / 10);
    return ProductModel(
      id: '${m['id'] ?? m[r'$id'] ?? ''}',
      name: '${m['name'] ?? ''}',
      price: price,
      salePrice: sale ?? (price > 250 ? price * 0.85 : null),
      description: '${m['description'] ?? ''}',
      category: '${m['category'] ?? 'Other'}',
      stock: stockQ,
      isInStock: stockQ > 0,
      images: imgs,
      iconName: '${m['icon'] ?? 'spa'}',
      rating: rating.clamp(3.5, 5.0),
      reviewsCount: (rating * 47).round(),
      badge: stockQ < 20 ? 'Low Stock' : (price > 400 ? 'Premium' : null),
    );
  }

  static IconData iconFromName(String name) {
    const map = {
      'grain': Icons.grain,
      'spa': Icons.spa,
      'water_drop': Icons.water_drop,
      'eco': Icons.eco,
      'local_florist': Icons.local_florist,
      'square': Icons.square_outlined,
      'cookie': Icons.cookie,
      'local_cafe': Icons.local_cafe,
      'card_giftcard': Icons.card_giftcard,
    };
    return map[name] ?? Icons.spa;
  }
}
