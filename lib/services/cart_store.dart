import 'package:flutter/material.dart';
import '../pages/products_page.dart';

/// Simple in-memory cart store — ValueNotifier so any widget can listen.
class CartItem {
  CartItem({required this.product, required this.qty, this.variantLabel, this.unitPrice});
  final Product product;
  int qty;
  final String? variantLabel;
  final double? unitPrice;

  double get price => unitPrice ?? product.price;
  double get total => price * qty;
}

class CartStore extends ChangeNotifier {
  CartStore._();
  static final CartStore instance = CartStore._();

  final ValueNotifier<List<CartItem>> items = ValueNotifier<List<CartItem>>([]);
  final ValueNotifier<Set<String>> wishlist = ValueNotifier<Set<String>>({});

  int get count => items.value.fold(0, (s, e) => s + e.qty);
  double get subtotal => items.value.fold(0, (s, e) => s + e.total);

  void add(Product product, {int qty = 1, String? variantLabel, double? unitPrice}) {
    final list = List<CartItem>.from(items.value);
    final key = '${product.id}::${variantLabel ?? ''}';
    final idx = list.indexWhere((e) => '${e.product.id}::${e.variantLabel ?? ''}' == key);
    if (idx >= 0) {
      list[idx].qty += qty;
    } else {
      list.add(CartItem(product: product, qty: qty, variantLabel: variantLabel, unitPrice: unitPrice ?? product.price));
    }
    items.value = list;
    notifyListeners();
  }

  void removeAt(int index) {
    final list = List<CartItem>.from(items.value)..removeAt(index);
    items.value = list;
    notifyListeners();
  }

  void setQty(int index, int qty) {
    if (qty <= 0) {
      removeAt(index);
      return;
    }
    final list = List<CartItem>.from(items.value);
    list[index].qty = qty;
    items.value = list;
    notifyListeners();
  }

  void clear() {
    items.value = [];
    notifyListeners();
  }

  bool isWishlisted(String productId) => wishlist.value.contains(productId);

  void toggleWishlist(String productId) {
    final next = Set<String>.from(wishlist.value);
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    wishlist.value = next;
    notifyListeners();
  }
}
