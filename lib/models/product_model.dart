import 'package:flutter/material.dart';

/// Strongly-typed Product model backed by the Appwrite `products` collection.
///
/// Expected DB schema (canonical, per task):
/// ```sql
/// id uuid, name text, description text, price numeric, stock_quantity int,
/// moq int, image_url text, category text, is_active bool, created_at timestamptz
/// -- legacy compat: product_id text, icon text, stock int, image_1/2/3 text
/// ```
/// FIX PGRST204: code now uses canonical image_url / stock_quantity; legacy
/// image_1/stock are read as fallback if present but never required for SELECT/INSERT.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.productId = '',
    this.description = '',
    this.imageUrl,
    this.category = 'Other',
    this.stockQuantity = 0,
    this.moq = 1,
    this.isActive = true,
    this.iconName = 'spa',
    this.image1,
    this.image2,
    this.image3,
    this.createdAt,
  });

  final String id;
  final String name;
  final double price;
  final String productId;
  final String description;
  final String? imageUrl;
  final String category;
  final int stockQuantity;
  final int moq;
  final bool isActive;
  final String iconName;
  final String? image1;
  final String? image2;
  final String? image3;
  final DateTime? createdAt;

  /// All non-empty image URLs (Appwrite URLs + asset paths) — deduped.
  List<String> get allImages {
    final imgs = <String>[];
    if (imageUrl != null && imageUrl!.isNotEmpty) imgs.add(imageUrl!);
    if (image2 != null && image2!.isNotEmpty && !imgs.contains(image2)) imgs.add(image2!);
    if (image3 != null && image3!.isNotEmpty && !imgs.contains(image3)) imgs.add(image3!);
    // image1 is duplicate of imageUrl, only add if distinct
    if (image1 != null && image1!.isNotEmpty && !imgs.contains(image1)) imgs.add(image1!);
    return imgs;
  }

  /// Placeholder icon resolved from the DB `icon` text field.
  IconData get placeholderIcon => _iconFromName(iconName);

  /// Formatted price string (e.g. "₹299").
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  bool get inStock => stockQuantity > 0;

  /// ── Deserialisation ──

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final primaryImage = _nonEmpty(json['image_url']?.toString()) ??
        _nonEmpty(json['image']?.toString()) ??
        _nonEmpty(json['image_1']?.toString());
    final img2 = _nonEmpty(json['image_2']?.toString()) ?? _nonEmpty(json['image2']?.toString()) ?? _nonEmpty(json['image_url_2']?.toString());
    final img3 = _nonEmpty(json['image_3']?.toString()) ?? _nonEmpty(json['image3']?.toString()) ?? _nonEmpty(json['image_url_3']?.toString());
    return ProductModel(
      id: json['id']?.toString() ?? json['\$id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parsePrice(json['price']),
      description: json['description']?.toString() ?? '',
      imageUrl: primaryImage,
      category: json['category']?.toString() ?? 'Other',
      stockQuantity: _parseInt(json['stock_quantity'] ?? json['stock']),
      moq: (_parseInt(json['moq'] ?? json['minimum_order_quantity'] ?? json['min_order_quantity'] ?? 1)).clamp(1, 999),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : (json['is_active']?.toString().toLowerCase() == 'true' ? true : (json['is_active'] == null ? true : false)),
      iconName: json['icon']?.toString() ?? 'spa',
      image1: primaryImage,
      image2: img2,
      image3: img3,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : (json['\$createdAt'] != null ? DateTime.tryParse(json['\$createdAt'].toString()) : null),
    );
  }

  /// ── Serialisation ──
  /// FIX PGRST204 + APPWRITE: only emits canonical columns (image_url, stock_quantity, is_active).
  /// Never writes image_1/image_2/image_3/stock to avoid column-does-not-exist errors
  /// (Appwrite error: "Unknown attribute: image_2" when collection missing that attribute).
  /// Callers needing image_2/3 must use AppwriteProductRepository which has graceful fallback.

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'product_id': productId,
      'name': name,
      'price': price,
      'description': description,
      'icon': iconName,
      'category': category,
      'stock_quantity': stockQuantity,
      'moq': moq,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
    final primary = _nonEmpty(imageUrl);
    if (primary != null) m['image_url'] = primary;
    // Do NOT emit image_2 / image_3 by default — collection may not have those attributes.
    // If you need them, use repository's normalized payload with fallback stripping.
    return m;
  }

  /// Extended payload that includes image_2/3 when present (for Appwrite with fallback).
  Map<String, dynamic> toJsonWithExtraImages() {
    final m = toJson();
    final i2 = _nonEmpty(image2);
    final i3 = _nonEmpty(image3);
    if (i2 != null) m['image_2'] = i2;
    if (i3 != null) m['image_3'] = i3;
    return m;
  }

  /// Convenience copyWith for immutable updates.
  ProductModel copyWith({
    String? id,
    String? productId,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    String? category,
    int? stockQuantity,
    int? moq,
    bool? isActive,
    String? iconName,
    String? image1,
    String? image2,
    String? image3,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      moq: moq ?? this.moq,
      isActive: isActive ?? this.isActive,
      iconName: iconName ?? this.iconName,
      image1: image1 ?? this.image1,
      image2: image2 ?? this.image2,
      image3: image3 ?? this.image3,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'ProductModel(id: $id, name: $name, price: $price)';

  // ── Helpers ──

  static double _parsePrice(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String? _nonEmpty(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }

  static IconData _iconFromName(String name) {
    const map = <String, IconData>{
      'grain': Icons.grain,
      'spa': Icons.spa,
      'water_drop': Icons.water_drop,
      'eco': Icons.eco,
      'local_florist': Icons.local_florist,
      'square': Icons.square_outlined,
      'cookie': Icons.cookie,
      'local_cafe': Icons.local_cafe,
      'card_giftcard': Icons.card_giftcard,
      'inventory_2': Icons.inventory_2,
      'shopping_bag': Icons.shopping_bag,
      'category': Icons.category,
    };
    return map[name] ?? Icons.spa;
  }
}
