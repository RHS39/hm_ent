import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/cart_store.dart';
import '../services/product_store.dart';
import '../services/scroll_manager.dart';
import 'products_page.dart';

IconData _iconFromName(String name) {
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
    'inventory_2': Icons.inventory_2,
    'shopping_bag': Icons.shopping_bag,
    'category': Icons.category,
  };
  return map[name] ?? Icons.spa;
}

/// Handles every product selection from the catalog — deep-link, search, category.
/// Renders real product when id is known (fallback list → Supabase), otherwise
/// shows friendly "not found" with CTA back to catalog.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId, this.initialProduct});

  final String productId;
  final Product? initialProduct;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with TickerProviderStateMixin {
  Product? _product;
  bool _loading = true;
  int _qty = 1;
  int _selectedVariant = 0;
  int _galleryIdx = 0;
  late PageController _galleryCtrl;
  late AnimationController _addAnim;
  bool _liked = false;
  late final ScrollController _scrollCtrl;
  String get _detailKey => 'product_${widget.productId}';

  // Expandable sections state
  final Map<String, bool> _expanded = {
    'details': true,
    'benefits': false,
    'ingredients': false,
    'storage': false,
    'shipping': false,
  };

  static const List<Product> _fallback = [
    Product(id: '1', productId: '01', name: 'Chocolaty Gud 700g', price: 299, imagePlaceholder: Icons.grain, description: '100% Natural • Unrefined • No Added Ingredients – Premium chocolaty jaggery chunks in glass jar by Hari Om Traders', imageAsset: 'assets/img/products/gud_700g.png', moq: 2),
    Product(id: '2', productId: '02', name: 'Organic Jaggery Cubes 1kg', price: 229, imagePlaceholder: Icons.spa, description: 'Traditional hand-cut cubes, rich iron & minerals', imageAsset: 'assets/img/products/organic-jaggery-cubes-1kg.png', moq: 2),
    Product(id: '3', productId: '03', name: 'Organic Liquid Jaggery Kakvi 500ml', price: 349, imagePlaceholder: Icons.water_drop, description: 'Thick liquid jaggery – natural sweetener', imageAsset: 'assets/img/products/organic-liquid-jaggery-kakvi-500ml.jpg', moq: 2),
    Product(id: '4', productId: '04', name: 'Organic Jaggery with Ginger 250g', price: 249, imagePlaceholder: Icons.eco, description: 'Infused with sun-dried ginger – digestive', imageAsset: 'assets/img/products/organic-jaggery-ginger-250g.png', moq: 2),
    Product(id: '5', productId: '05', name: 'Organic Jaggery with Moringa 250g', price: 279, imagePlaceholder: Icons.local_florist, description: 'Moringa leaf superfood blend', imageAsset: 'assets/img/products/organic-jaggery-moringa-250g.jpg', moq: 2),
    Product(id: '6', productId: '06', name: 'Organic Jaggery with Turmeric 250g', price: 269, imagePlaceholder: Icons.spa, description: 'Golden turmeric – immunity boosting', imageAsset: 'assets/img/products/organic-jaggery-turmeric-250g.png', moq: 2),
    Product(id: '7', productId: '07', name: 'Organic Jaggery Block 1kg', price: 249, imagePlaceholder: Icons.square_outlined, description: 'Traditional solid block – wood-pressed juice', imageAsset: 'assets/img/products/organic-jaggery-block-1kg.png', moq: 2),
    Product(id: '8', productId: '08', name: 'Organic Granular Jaggery 1kg', price: 229, imagePlaceholder: Icons.grain, description: 'Free-flowing granular – easy to dissolve', imageAsset: 'assets/img/products/organic-granular-jaggery-1kg.png', moq: 2),
    Product(id: '9', productId: '09', name: 'Organic Jaggery Peanut Chikki 200g', price: 179, imagePlaceholder: Icons.cookie, description: 'Crunchy peanut brittle with jaggery', imageAsset: 'assets/img/products/organic-jaggery-peanut-chikki-200g.png', moq: 2),
    Product(id: '10', productId: '10', name: 'Organic Jaggery Sesame Chikki 200g', price: 189, imagePlaceholder: Icons.cookie, description: 'Roasted sesame & jaggery – calcium rich', imageAsset: 'assets/img/products/organic-jaggery-sesame-chikki-200g.jpg', moq: 2),
    Product(id: '11', productId: '11', name: 'Organic Jaggery Coconut Chikki 200g', price: 199, imagePlaceholder: Icons.cookie, description: 'Coconut flakes with jaggery', imageAsset: 'assets/img/products/organic-jaggery-coconut-chikki-200g.png', moq: 2),
    Product(id: '12', productId: '12', name: 'Organic Jaggery Tea Blend 100g', price: 299, imagePlaceholder: Icons.local_cafe, description: 'Jaggery powder for chai – dissolves instantly', imageAsset: 'assets/img/products/organic-jaggery-tea-blend-100g.jpg', moq: 1),
    Product(id: '13', productId: '13', name: 'Organic Jaggery Syrup 500ml', price: 329, imagePlaceholder: Icons.water_drop, description: 'Pourable syrup for pancakes & porridge', imageAsset: 'assets/img/products/organic-jaggery-syrup-500ml.png', moq: 1),
    Product(id: '14', productId: '14', name: 'Organic Jaggery with Cardamom 250g', price: 289, imagePlaceholder: Icons.eco, description: 'Aromatic cardamom infusion', imageAsset: 'assets/img/products/organic-jaggery-cardamom-250g.png', moq: 2),
    Product(id: '15', productId: '15', name: 'Organic Jaggery Gift Hamper 1.5kg', price: 899, imagePlaceholder: Icons.card_giftcard, description: 'Assorted hamper – festive gift', imageAsset: 'assets/img/products/organic-jaggery-gift-hamper-1-5kg.jpg', moq: 1),
  ];

  // Variant packs — interactive selection (mock pricing by weight multiplier)
  List<Map<String, dynamic>> get _variants {
    if (_product == null) return [];
    final base = _product!.price;
    final name = _product!.name.toLowerCase();
    if (name.contains('chikki') || name.contains('hamper') || name.contains('tea blend')) {
      // single SKU — no variants
      return [
        {'label': _weightOf(_product!.name) ?? 'Pack', 'price': base, 'strike': base * 1.18},
      ];
    }
    // generic jaggery — offer 250g / 500g / 1kg tiers relative to parsed weight
    final parsed = RegExp(r'(\d+)\s*(g|kg|ml)', caseSensitive: false).firstMatch(name);
    double baseW = 500;
    if (parsed != null) {
      final v = double.tryParse(parsed.group(1)!) ?? 500;
      final unit = parsed.group(2)!.toLowerCase();
      baseW = unit == 'kg' ? v * 1000 : v;
    }
    double pFor(double w) => base * (w / baseW);
    return [
      {'label': '250g', 'weight': 250.0, 'price': pFor(250), 'strike': pFor(250) * 1.18},
      {'label': '500g', 'weight': 500.0, 'price': pFor(500), 'strike': pFor(500) * 1.18},
      {'label': '1kg', 'weight': 1000.0, 'price': pFor(1000), 'strike': pFor(1000) * 1.18},
    ];
  }

  String? _weightOf(String n) {
    final m = RegExp(r'(\d+(\.\d+)?\s?(g|kg|ml)\b)', caseSensitive: false).firstMatch(n);
    return m?.group(0)?.toUpperCase();
  }

  int _moqFor(Product p) {
    if (p.moq >= 1 && p.moq <= 999) return p.moq;
    final n = p.name.toLowerCase();
    if (n.contains('hamper')) return 1;
    if (n.contains('chikki')) return 2;
    if (n.contains('tea blend')) return 1;
    return 2;
  }

  int get _moq => _product == null ? 2 : _moqFor(_product!);

  @override
  void initState() {
    super.initState();
    _galleryCtrl = PageController();
    _addAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _scrollCtrl = ScrollManager.instance.controllerFor(_detailKey);
    // restore after first frame — back navigation lands at same spot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final saved = ScrollManager.instance.getOffset(_detailKey);
        if (saved > 0 && (_scrollCtrl.offset - saved).abs() > 1) {
          _scrollCtrl.jumpTo(saved.clamp(0, _scrollCtrl.position.maxScrollExtent));
        }
      }
    });
    _resolve();
    // sync wishlist initial
    _liked = CartStore.instance.isWishlisted(widget.productId);
  }

  Future<void> _resolve() async {
    // 1) use injected product if matches id (from catalog tap via extra)
    if (widget.initialProduct != null && widget.initialProduct!.id == widget.productId) {
      final prod = widget.initialProduct!;
      setState(() {
        _product = prod;
        _loading = false;
        _selectedVariant = _defaultVariantIndex(prod);
        _liked = CartStore.instance.isWishlisted(prod.id);
        _qty = _moqFor(prod);
      });
      return;
    }
    // 2) fallback lookup
    final fb = _fallback.where((p) => p.id == widget.productId).toList();
    if (fb.isNotEmpty) {
      final prod = fb.first;
      setState(() {
        _product = prod;
        _loading = false;
        _selectedVariant = _defaultVariantIndex(prod);
        _liked = CartStore.instance.isWishlisted(prod.id);
        _qty = _moqFor(prod);
      });
      // try to enrich from Appwrite in background (no block)
      _enrichFromAppwrite(widget.productId);
      return;
    }
    // 3) try Appwrite by id or name slug
    await _enrichFromAppwrite(widget.productId);
    if (_product == null && mounted) {
      setState(() => _loading = false);
    }
  }

  int _defaultVariantIndex(Product p) {
    // select variant whose label matches product weight
    final w = _weightOf(p.name)?.toLowerCase().replaceAll(' ', '');
    final vars = _variantsFor(p);
    if (w == null || vars.length == 1) return 0;
    final idx = vars.indexWhere((v) => (v['label'] as String).toLowerCase().replaceAll(' ', '') == w);
    return idx >= 0 ? idx : (vars.length > 1 ? 1 : 0);
  }

  List<Map<String, dynamic>> _variantsFor(Product p) {
    final base = p.price;
    final name = p.name.toLowerCase();
    if (name.contains('chikki') || name.contains('hamper') || name.contains('tea blend')) return [{'label': _weightOf(p.name) ?? 'Pack', 'price': base}];
    final parsed = RegExp(r'(\d+)\s*(g|kg|ml)', caseSensitive: false).firstMatch(name);
    double baseW = 500;
    if (parsed != null) {
      final v = double.tryParse(parsed.group(1)!) ?? 500;
      final unit = parsed.group(2)!.toLowerCase();
      baseW = unit == 'kg' ? v * 1000 : v;
    }
    double pFor(double w) => base * (w / baseW);
    return [
      {'label': '250g', 'weight': 250.0, 'price': pFor(250), 'strike': pFor(250) * 1.18},
      {'label': '500g', 'weight': 500.0, 'price': pFor(500), 'strike': pFor(500) * 1.18},
      {'label': '1kg', 'weight': 1000.0, 'price': pFor(1000), 'strike': pFor(1000) * 1.18},
    ];
  }

  Future<void> _enrichFromAppwrite(String id) async {
    try {
      // Use ProductStore as single source of truth
      if (!ProductStore.instance.loaded) {
        await ProductStore.instance.load();
      }
      final rows = ProductStore.instance.products;
      if (rows.isEmpty) return;
      // try match by id or slugified name
      for (final r in rows) {
        final rid = '${r['id']}';
        final rname = '${r['name']}';
        final slug = rname.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        if (rid == id || slug == id.toLowerCase() || rname.toLowerCase() == id.toLowerCase()) {
          final price = r['price'] is num ? (r['price'] as num).toDouble() : double.tryParse('${r['price']}') ?? 0;
          final prod = Product(
            id: rid,
            productId: '${r['product_id']}'.isNotEmpty ? '${r['product_id']}' : '00',
            name: rname,
            price: price,
            description: r['description'] as String?,
            imagePlaceholder: _iconFromName('${r['icon']}'),
            imageAsset: _assetForName(rname),
            // Use canonical image_url + extra images; null-safe
            image1: (r['image_url'] ?? r['image'])?.toString().isEmpty == true ? null : (r['image_url'] ?? r['image']) as String?,
            image2: (r['image_2']?.toString().isEmpty == true ? null : r['image_2'] as String?),
            image3: (r['image_3']?.toString().isEmpty == true ? null : r['image_3'] as String?),
            moq: (int.tryParse('${r['moq'] ?? r['minimum_order_quantity'] ?? 2}') ?? 2).clamp(1, 999),
          );
          if (mounted) {
            setState(() {
              _product = prod;
              _loading = false;
              _selectedVariant = _defaultVariantIndex(prod);
              // enforce MOQ when enriching
              if (_qty < _moqFor(prod)) _qty = _moqFor(prod);
            });
          }
          return;
        }
      }
    } catch (_) {}
  }

  String? _assetForName(String name) {
    const map = {
      'Chocolaty Gud 700g': 'assets/img/products/gud_700g.png',
      'Hari Om Traders Chocolaty Gud 700g': 'assets/img/products/gud_700g.png',
      'Organic Chocolaty Gud 700g': 'assets/img/products/gud_700g.png',
      'Organic Jaggery Powder 500g': 'assets/img/products/gud_700g.png',
      'Organic Jaggery Cubes 1kg': 'assets/img/products/organic-jaggery-cubes-1kg.png',
      'Organic Liquid Jaggery Kakvi 500ml': 'assets/img/products/organic-liquid-jaggery-kakvi-500ml.jpg',
      'Organic Jaggery with Ginger 250g': 'assets/img/products/organic-jaggery-ginger-250g.png',
      'Organic Jaggery with Moringa 250g': 'assets/img/products/organic-jaggery-moringa-250g.jpg',
      'Organic Jaggery with Turmeric 250g': 'assets/img/products/organic-jaggery-turmeric-250g.png',
      'Organic Jaggery Block 1kg': 'assets/img/products/organic-jaggery-block-1kg.png',
      'Organic Granular Jaggery 1kg': 'assets/img/products/organic-granular-jaggery-1kg.png',
      'Organic Jaggery Peanut Chikki 200g': 'assets/img/products/organic-jaggery-peanut-chikki-200g.png',
      'Organic Jaggery Sesame Chikki 200g': 'assets/img/products/organic-jaggery-sesame-chikki-200g.jpg',
      'Organic Jaggery Coconut Chikki 200g': 'assets/img/products/organic-jaggery-coconut-chikki-200g.png',
      'Organic Jaggery Tea Blend 100g': 'assets/img/products/organic-jaggery-tea-blend-100g.jpg',
      'Organic Jaggery Syrup 500ml': 'assets/img/products/organic-jaggery-syrup-500ml.png',
      'Organic Jaggery with Cardamom 250g': 'assets/img/products/organic-jaggery-cardamom-250g.png',
      'Organic Jaggery Gift Hamper 1.5kg': 'assets/img/products/organic-jaggery-gift-hamper-1-5kg.jpg',
    };
    return map[name];
  }

  @override
  void dispose() {
    // persist product detail scroll offset before state dies (browser back needs it)
    ScrollManager.instance.saveOffset(_detailKey, _scrollCtrl.hasClients ? _scrollCtrl.offset : ScrollManager.instance.getOffset(_detailKey));
    _galleryCtrl.dispose();
    _addAnim.dispose();
    super.dispose();
  }

  double get _currentPrice {
    if (_product == null) return 0;
    if (_variants.isEmpty) return _product!.price;
    final v = _variants[_selectedVariant.clamp(0, _variants.length - 1)];
    return (v['price'] as double);
  }

  double get _currentStrike {
    if (_variants.isEmpty) return _product!.price * 1.18;
    final v = _variants[_selectedVariant.clamp(0, _variants.length - 1)];
    return (v['strike'] as double?) ?? _currentPrice * 1.18;
  }

  String get _currentVariantLabel {
    if (_variants.isEmpty) return _weightOf(_product!.name) ?? 'Pack';
    return _variants[_selectedVariant.clamp(0, _variants.length - 1)]['label'] as String;
  }

  List<String> get _galleryUrls {
    if (_product == null) return [];
    // Only use network URLs from image1/image2/image3 — skip local asset fallbacks
    final imgs = <String>[];
    if (_product!.image1 != null && _product!.image1!.isNotEmpty) imgs.add(_product!.image1!);
    if (_product!.image2 != null && _product!.image2!.isNotEmpty) imgs.add(_product!.image2!);
    if (_product!.image3 != null && _product!.image3!.isNotEmpty) imgs.add(_product!.image3!);
    if (imgs.isNotEmpty) return imgs.take(3).toList();
    if (_product!.imageAsset != null && _product!.imageAsset!.isNotEmpty) return [_product!.imageAsset!];
    const fallback = 'https://images.unsplash.com/photo-1587049352851-8d4e89133924?w=800&q=80';
    return [fallback];
  }

  Widget _cartThumb(Product prod) {
    final imgs = prod.allImages;
    String? best;
    for (final u in imgs) {
      if (u.startsWith('http://') || u.startsWith('https://')) {
        best = u;
        break;
      }
    }
    best ??= imgs.isNotEmpty ? imgs.first : prod.imageAsset;
    if (best != null && best.isNotEmpty) {
      if (best.startsWith('assets/')) {
        return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(best, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(prod.imagePlaceholder, color: const Color(0xFF00C805))));
      } else if (best.startsWith('http')) {
        return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(best, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
              // fallback to asset if network fails
              if (prod.imageAsset != null) return Image.asset(prod.imageAsset!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(prod.imagePlaceholder, color: const Color(0xFF00C805)));
              return Icon(prod.imagePlaceholder, color: const Color(0xFF00C805), size: 22);
            }));
      }
    }
    return Icon(prod.imagePlaceholder, color: const Color(0xFF00C805), size: 22);
  }

  void _addToCart({bool buyNow = false}) {
    if (_product == null) return;
    if (_qty < _moq) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minimum order is $_moq ${ _moq == 1 ? 'unit' : 'units'} for ${ _product!.name}'), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF92400E)));
      setState(() => _qty = _moq);
      return;
    }
    HapticFeedback.mediumImpact();
    _addAnim.forward().then((_) => _addAnim.reverse());
    CartStore.instance.add(_product!, qty: _qty, variantLabel: _currentVariantLabel, unitPrice: _currentPrice);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0B0E0F),
        duration: const Duration(milliseconds: 1400),
        content: Text(buyNow ? 'Proceeding to checkout — ${_product!.name} ×$_qty (${_currentVariantLabel})' : 'Added ${_product!.name} ×$_qty (${_currentVariantLabel}) to cart'),
        action: SnackBarAction(label: 'View cart', textColor: const Color(0xFF00C805), onPressed: () {
          // simple cart preview bottom sheet
          _showCartSheet();
        }),
      ),
    );
    if (buyNow) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _showCartSheet(checkoutMode: true);
      });
    }
  }

  void _showCartSheet({bool checkoutMode = false}) {
    final cart = CartStore.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, sc) {
          return ValueListenableBuilder<List<CartItem>>(
            valueListenable: cart.items,
            builder: (context, items, __) {
              final subtotal = cart.subtotal;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(100))),
                    const SizedBox(height: 12),
                    Row(children: [
                      Text(checkoutMode ? 'Checkout' : 'Your cart', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('${cart.count} items', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black54, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      TextButton(onPressed: cart.clear, child: const Text('Clear')),
                    ]),
                    const Divider(height: 1),
                    Expanded(
                      child: items.isEmpty
                          ? Center(child: Text('Cart empty — add something delicious', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)))
                          : ListView.separated(
                              controller: sc,
                              padding: const EdgeInsets.only(top: 12),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final it = items[i];
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                                  child: Row(children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                                      clipBehavior: Clip.antiAlias,
                                      child: _cartThumb(it.product),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(it.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      if (it.variantLabel != null) Text(it.variantLabel!, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                      Text('₹${it.price.toStringAsFixed(0)} × ${it.qty}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00A63E))),
                                    ])),
                                    Row(children: [
                                      IconButton(onPressed: () => cart.setQty(i, it.qty - 1), icon: const Icon(Icons.remove_circle_outline, size: 20)),
                                      Text('${it.qty}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                      IconButton(onPressed: () => cart.setQty(i, it.qty + 1), icon: const Icon(Icons.add_circle_outline, size: 20)),
                                    ]),
                                  ]),
                                );
                              },
                            ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Column(children: [
                        const SizedBox(height: 10),
                        Row(children: [const Text('Subtotal', style: TextStyle(color: Color(0xFF6B7280))), const Spacer(), Text('₹${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
                        const SizedBox(height: 4),
                        Row(children: [Text(subtotal >= 499 ? 'Free delivery unlocked' : 'Add ₹${(499 - subtotal).clamp(0, 9999).toStringAsFixed(0)} more for free delivery', style: TextStyle(fontSize: 11, color: subtotal >= 499 ? const Color(0xFF00A63E) : const Color(0xFF6B7280)))]),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: FilledButton(onPressed: items.isEmpty ? null : () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed — demo checkout'))); }, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))), child: Text(checkoutMode ? 'Place order — ₹${subtotal.toStringAsFixed(0)}' : 'Checkout — ₹${subtotal.toStringAsFixed(0)}'))),
                      ]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImage(String src, {BoxFit fit = BoxFit.cover}) {
    final isAsset = src.startsWith('assets/');
    if (isAsset) {
      return Image.asset(src, fit: fit, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    return Image.network(src, fit: fit, width: double.infinity, height: double.infinity, loadingBuilder: (c, ch, p) => p == null ? ch : Container(color: const Color(0xFF00C805).withOpacity(0.08), child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C805))))), errorBuilder: (_, __, ___) => _fallbackIcon());
  }

  Widget _fallbackIcon() {
    return Container(color: const Color(0xFFF3F4F6), child: Center(child: Icon(_product?.imagePlaceholder ?? Icons.spa, size: 44, color: const Color(0xFF00C805).withOpacity(0.7))));
  }

  bool get _isBestSeller => _product != null && (_product!.id == '1' || _product!.id == '9' || _product!.name.toLowerCase().contains('gud'));
  bool get _isNew => _product != null && (_product!.id == '5' || _product!.id == '14');

  Color _bgFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('chikki')) return const Color(0xFFFEF3C7);
    if (n.contains('kakvi') || n.contains('syrup') || n.contains('liquid')) return const Color(0xFFEFF6FF);
    if (n.contains('tea')) return const Color(0xFFFEFCE8);
    if (n.contains('hamper')) return const Color(0xFFFAF5FF);
    if (n.contains('ginger') || n.contains('turmeric') || n.contains('moringa') || n.contains('cardamom')) return const Color(0xFFECFDF5);
    return const Color(0xFFFFF7ED);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/products'))),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00C805))),
      );
    }
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/products'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              Text('Product not found', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('No product matches “${widget.productId}”. It may have been removed or the link is wrong.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => context.go('/products'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F)), child: const Text('Browse catalog')),
            ]),
          ),
        ),
      );
    }

    final p = _product!;
    final mrp = _currentStrike;
    final discountPct = (((mrp - _currentPrice) / mrp) * 100).round().clamp(0, 90);
    final weight = _weightOf(p.name);
    final related = _fallback.where((e) => e.id != p.id).take(6).toList();

    // responsive
    final screenW = MediaQuery.sizeOf(context).width;
    final isWide = screenW >= 900;
    const maxW = 1180.0;
    final hPad = isWide ? 16.0 : 16.0;

    // Modern breadcrumb: Home / Products / Category / Product
    String categoryLabel(String name) {
      final n = name.toLowerCase();
      if (n.contains('chikki')) return 'Chikki';
      if (n.contains('kakvi') || n.contains('syrup')) return 'Syrup & Kakvi';
      if (n.contains('powder') || n.contains('granular')) return 'Pouches';
      if (n.contains('block') || n.contains('cube')) return 'Blocks';
      if (n.contains('ginger') || n.contains('moringa') || n.contains('turmeric') || n.contains('cardamom') || n.contains('tea')) return 'Spiced';
      if (n.contains('hamper')) return 'Gifting';
      return 'Jaggery';
    }

    final category = categoryLabel(p.name);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0E0F) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF0B0E0F)), onPressed: () => context.canPop() ? context.pop() : context.go('/products')),
        title: isWide ? Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0B0E0F))) : null,
        centerTitle: false,
        actions: [
          IconButton(onPressed: () { HapticFeedback.lightImpact(); final m = 'Check out ${p.name} on Hari Om Traders'; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shared: $m'), behavior: SnackBarBehavior.floating)); }, icon: Icon(Icons.share_outlined, size: 20, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
          ValueListenableBuilder<Set<String>>(
            valueListenable: CartStore.instance.wishlist,
            builder: (_, wl, __) {
              final liked = wl.contains(p.id);
              return IconButton(onPressed: () { HapticFeedback.selectionClick(); CartStore.instance.toggleWishlist(p.id); }, icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20, color: liked ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : const Color(0xFF6B7280))));
            },
          ),
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: CartStore.instance.items,
            builder: (_, items, __) {
              final c = items.fold<int>(0, (s, e) => s + e.qty);
              return Stack(children: [
                IconButton(onPressed: _showCartSheet, icon: Icon(Icons.shopping_bag_outlined, size: 20, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
                if (c > 0) Positioned(right: 6, top: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(100)), child: Text('$c', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
              ]);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            key: PageStorageKey<String>(_detailKey),
            controller: _scrollCtrl,
            padding: EdgeInsets.only(bottom: isWide ? 24 : 88),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxW),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── BREADCRUMB (modern top navigation) ──
                      _Breadcrumb(category: category, productName: p.name, isDark: isDark),
                      const SizedBox(height: 10),
                      isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Gallery sticky left — modern: thumbnails vertical, main image dominant
                                Expanded(flex: 12, child: _GalleryCard(galleryUrls: _galleryUrls, bg: _bgFor(p.name), isBestSeller: _isBestSeller, isNew: _isNew, weight: weight, controller: _galleryCtrl, idx: _galleryIdx, onChanged: (i) => setState(() => _galleryIdx = i), isWide: true)),
                                const SizedBox(width: 24),
                                // Info scrolls independently on desktop
                                Expanded(flex: 11, child: _InfoColumn(product: p, price: _currentPrice, strike: _currentStrike, discountPct: discountPct, variantLabel: _currentVariantLabel, variants: _variants, selectedVariant: _selectedVariant, qty: _qty, moq: _moq, onVariant: (i) => setState(() => _selectedVariant = i), onQty: (v) => setState(() => _qty = v.clamp(_moq, 99)), onAdd: _addToCart, weight: weight, expanded: _expanded, onToggle: (k) => setState(() => _expanded[k] = !(_expanded[k] ?? false)), isDark: isDark, addAnim: _addAnim, liked: _liked)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _GalleryCard(galleryUrls: _galleryUrls, bg: _bgFor(p.name), isBestSeller: _isBestSeller, isNew: _isNew, weight: weight, controller: _galleryCtrl, idx: _galleryIdx, onChanged: (i) => setState(() => _galleryIdx = i), isWide: false),
                                const SizedBox(height: 14),
                                _InfoColumn(product: p, price: _currentPrice, strike: _currentStrike, discountPct: discountPct, variantLabel: _currentVariantLabel, variants: _variants, selectedVariant: _selectedVariant, qty: _qty, moq: _moq, onVariant: (i) => setState(() => _selectedVariant = i), onQty: (v) => setState(() => _qty = v.clamp(_moq, 99)), onAdd: _addToCart, weight: weight, expanded: _expanded, onToggle: (k) => setState(() => _expanded[k] = !(_expanded[k] ?? false)), isDark: isDark, addAnim: _addAnim, liked: _liked),
                                const SizedBox(height: 18),
                                _RelatedStrip(related: related, isDark: isDark, onTap: (prod) => context.push('/product/${prod.id}', extra: prod)),
                              ],
                            ),
                      if (isWide) ...[
                        const SizedBox(height: 28),
                        _RelatedStrip(related: related, isDark: isDark, onTap: (prod) => context.push('/product/${prod.id}', extra: prod)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!isWide)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _StickyBuyBar(price: _currentPrice, qty: _qty, moq: _moq, addAnim: _addAnim, onAdd: () => _addToCart(buyNow: false), onBuy: () => _addToCart(buyNow: true), isDark: isDark),
            ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.category, required this.productName, required this.isDark});
  final String category;
  final String productName;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final muted = isDark ? Colors.white54 : const Color(0xFF9CA3AF);
    final active = isDark ? Colors.white : const Color(0xFF0B0E0F);
    TextStyle link(bool isActive) => TextStyle(fontSize: 12.5, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? active : muted);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        InkWell(onTap: () => context.go('/'), borderRadius: BorderRadius.circular(6), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: Row(children: [Icon(Icons.home_outlined, size: 14, color: muted), const SizedBox(width: 4), Text('Home', style: link(false))]))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right_rounded, size: 14, color: muted)),
        InkWell(onTap: () => context.go('/products'), borderRadius: BorderRadius.circular(6), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Products', style: link(false)))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right_rounded, size: 14, color: muted)),
        InkWell(onTap: () => context.go('/products'), borderRadius: BorderRadius.circular(6), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(category, style: link(false)))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right_rounded, size: 14, color: muted)),
        ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.45), child: Text(productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: link(true))),
      ]),
    );
  }
}

/// Aliexpress-style gallery — hover magnifier (desktop) + fullscreen zoom dialog.
/// Reference: https://www.aliexpress.com/item/1005007711820842.html magnifier lens + side zoom pane.
class _GalleryCard extends StatefulWidget {
  const _GalleryCard({required this.galleryUrls, required this.bg, required this.isBestSeller, required this.isNew, required this.weight, required this.controller, required this.idx, required this.onChanged, this.isWide = false});
  final List<String> galleryUrls;
  final Color bg;
  final bool isBestSeller;
  final bool isNew;
  final String? weight;
  final PageController controller;
  final int idx;
  final ValueChanged<int> onChanged;
  final bool isWide;

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {

  Widget _thumb(String url, bool selected, double size) {
    final isAsset = url.startsWith('assets/');
    Widget img = isAsset
        ? Image.asset(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _thumbFallback())
        : Image.network(url, fit: BoxFit.cover, loadingBuilder: (c, ch, p) => p == null ? ch : _thumbFallback(), errorBuilder: (_, __, ___) => _thumbFallback());
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? const Color(0xFF00C805) : const Color(0xFFE5E7EB), width: selected ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: img,
    );
  }

  Widget _thumbFallback() => Container(color: const Color(0xFFF3F4F6), child: const Icon(Icons.image, size: 16, color: Color(0xFF9CA3AF)));

  Widget _mainImageWidget(String url) {
    final isAsset = url.startsWith('assets/');
    if (url.isEmpty) return Container(color: widget.bg, child: const Icon(Icons.image, size: 48, color: Color(0xFF9CA3AF)));
    if (isAsset) {
      return Image.asset(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => Container(color: widget.bg, child: const Icon(Icons.image, size: 48, color: Color(0xFF9CA3AF))));
    }
    return Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity, loadingBuilder: (c, ch, p) => p == null ? ch : Container(color: widget.bg, child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C805))))), errorBuilder: (_, __, ___) => Container(color: widget.bg, child: const Icon(Icons.image, size: 48, color: Color(0xFF9CA3AF))));
  }



  @override
  Widget build(BuildContext context) {
    final safeIdx = widget.galleryUrls.isEmpty ? 0 : widget.idx.clamp(0, widget.galleryUrls.length - 1);
    // sanitize url: ensure non-empty and valid
    String rawUrl = widget.galleryUrls.isNotEmpty ? widget.galleryUrls[safeIdx] : '';
    // guard against numeric or invalid urls (e.g., "70")
    bool isValidUrl(String u) {
      if (u.trim().isEmpty) return false;
      if (u.trim() == '70' || u.trim().length < 4) return false;
      return u.startsWith('assets/') || u.startsWith('http://') || u.startsWith('https://');
    }
    String url = isValidUrl(rawUrl) ? rawUrl : '';
    // if gallery contains invalid entries, fallback to first valid or empty
    if (url.isEmpty && widget.galleryUrls.isNotEmpty) {
      for (final u in widget.galleryUrls) {
        if (isValidUrl(u)) { url = u; break; }
      }
    }
    final hasMultiple = widget.galleryUrls.where((u) => isValidUrl(u)).length > 1;

    // Main image without zoom — static display
    Widget mainImageInner = AspectRatio(
      aspectRatio: widget.isWide ? 0.95 : 1.05,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: widget.bg, child: Hero(tag: 'product-image-${widget.galleryUrls.isNotEmpty ? widget.galleryUrls.first : 'single'}', child: _mainImageWidget(url))),
          Positioned(
              top: 12,
              left: 12,
              child: Row(children: [
                if (widget.isBestSeller) Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF0B0E0F), borderRadius: BorderRadius.circular(100)), child: const Text('BESTSELLER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4))),
                if (widget.isNew) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(100)), child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))],
              ])),
          if (widget.weight != null) Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.96), borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)]), child: Text(widget.weight!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF0B0E0F))))),
        ],
      ),
    );

    Widget mainImageWide = Expanded(child: mainImageInner);
    Widget mainImageNarrow = mainImageInner;

    // Thumbnail strip — only valid urls
    final validUrls = widget.galleryUrls.where((u) => isValidUrl(u)).take(5).toList();
    final thumbsCount = validUrls.length;
    final hasValidMultiple = thumbsCount > 1;
    Widget thumbs;
    if (widget.isWide) {
      thumbs = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < thumbsCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(onTap: () => widget.onChanged(widget.galleryUrls.indexOf(validUrls[i])), child: _thumb(validUrls[i], validUrls[safeIdx.clamp(0, thumbsCount-1)] == validUrls[i], 56)),
            ),
        ],
      );
    } else {
      thumbs = hasValidMultiple
          ? Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < thumbsCount; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(onTap: () => widget.onChanged(widget.galleryUrls.indexOf(validUrls[i])), child: _thumb(validUrls[i], validUrls[safeIdx.clamp(0, thumbsCount-1)] == validUrls[i], 48)),
                    ),
                ],
              ),
            )
          : const SizedBox.shrink();
    }

    // Layout — desktop adds zoom pane
    Widget content;
    if (widget.isWide) {
      content = Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasValidMultiple) ...[
              thumbs,
              const SizedBox(width: 12),
            ],
            mainImageWide,
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            mainImageNarrow,
            thumbs,
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8))]),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: content),
    );
  }
}

/// Fullscreen zoom dialog — swipeable, pinch-zoom, dots + thumbnails (aliexpress)
class _FullscreenZoomDialog extends StatefulWidget {
  const _FullscreenZoomDialog({required this.urls, required this.initialIndex, required this.bg});
  final List<String> urls;
  final int initialIndex;
  final Color bg;
  @override
  State<_FullscreenZoomDialog> createState() => _FullscreenZoomDialogState();
}

class _FullscreenZoomDialogState extends State<_FullscreenZoomDialog> {
  late PageController _pc;
  late int _idx;
  final TransformationController _trans = TransformationController();

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pc = PageController(initialPage: _idx);
  }

  @override
  void dispose() {
    _pc.dispose();
    _trans.dispose();
    super.dispose();
  }

  Widget _buildImage(String url, bool active) {
    final isAsset = url.startsWith('assets/');
    final img = isAsset
        ? Image.asset(url, fit: BoxFit.contain)
        : Image.network(url, fit: BoxFit.contain, loadingBuilder: (c, ch, p) => p == null ? ch : const Center(child: CircularProgressIndicator(color: Color(0xFF00C805))), errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54));
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      panEnabled: true,
      scaleEnabled: true,
      child: Center(child: Hero(tag: 'zoom-$url-$_idx', child: img)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isWide = w >= 700;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // backdrop tap to close
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(color: Colors.black.withOpacity(0.88))),
          // centered viewer
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 980 : w, maxHeight: MediaQuery.sizeOf(context).height * 0.92),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(100)), child: Text('${_idx + 1} / ${widget.urls.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.12))),
                    ]),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pc,
                      onPageChanged: (v) => setState(() => _idx = v),
                      itemCount: widget.urls.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(color: Colors.white, child: _buildImage(widget.urls[i], i == _idx))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // dots
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.urls.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 3), width: i == _idx ? 20 : 7, height: 7, decoration: BoxDecoration(color: i == _idx ? const Color(0xFF00C805) : Colors.white.withOpacity(0.45), borderRadius: BorderRadius.circular(100))))),
                  const SizedBox(height: 10),
                  // thumbnails
                  SizedBox(
                    height: 62,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.urls.length.clamp(0, 10),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final sel = i == _idx;
                        final url = widget.urls[i];
                        final isAsset = url.startsWith('assets/');
                        return GestureDetector(
                          onTap: () {
                            _pc.animateToPage(i, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
                            setState(() => _idx = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 62,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? const Color(0xFF00C805) : Colors.white.withOpacity(0.22), width: sel ? 2 : 1)),
                            clipBehavior: Clip.antiAlias,
                            child: isAsset ? Image.asset(url, fit: BoxFit.cover) : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1F2429))),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Pinch to zoom \u2022 Double-tap \u2022 Swipe \u2022 ESC to close', style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.product, required this.price, required this.strike, required this.discountPct, required this.variantLabel, required this.variants, required this.selectedVariant, required this.qty, required this.moq, required this.onVariant, required this.onQty, required this.onAdd, required this.weight, required this.expanded, required this.onToggle, required this.isDark, required this.addAnim, required this.liked});
  final Product product;
  final double price;
  final double strike;
  final int discountPct;
  final String variantLabel;
  final List<Map<String, dynamic>> variants;
  final int selectedVariant;
  final int qty;
  final int moq;
  final ValueChanged<int> onVariant;
  final ValueChanged<int> onQty;
  final void Function({bool buyNow}) onAdd;
  final String? weight;
  final Map<String, bool> expanded;
  final ValueChanged<String> onToggle;
  final bool isDark;
  final AnimationController addAnim;
  final bool liked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    // Helpers for modern price styling
    String sku = '#HOT-${product.id.padLeft(4, '0')}';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── 1. META ROW (modern: category pill + SKU + stock, above title)
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00C805), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(sku, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(100)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, size: 12, color: const Color(0xFF15803D)), const SizedBox(width: 4), Text('In stock', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)))]),
        ),
        const Spacer(),
        Text(variantLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
      ]),
      const SizedBox(height: 10),

      // ── 2. TITLE (H1, dominant)
      Text(product.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: MediaQuery.sizeOf(context).width < 360 ? 20 : 22, height: 1.15, letterSpacing: -0.4, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
      const SizedBox(height: 8),

      // ── 3. RATING + REVIEWS + ORGANIC BADGE (directly under title, modern inline) — responsive wrap
      Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF00A63E), borderRadius: BorderRadius.circular(100)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star_rounded, size: 12, color: Colors.white), const SizedBox(width: 3), Text('4.8', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11))]),
          ),
          Text('(1,234 reviews)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : const Color(0xFF6B7280), decoration: TextDecoration.underline)),
          Text('•', style: TextStyle(color: isDark ? Colors.white24 : const Color(0xFFE5E7EB))),
          Text('1.2k+ sold', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFFD1FAE5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_rounded, size: 12, color: const Color(0xFF00A63E)), const SizedBox(width: 4), Text('Organic', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF00A63E)))])),
        ],
      ),
      const SizedBox(height: 10),

      // ── 4. SHORT DESCRIPTION
      if (product.description != null) ...[
        Text(product.description!, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white70 : const Color(0xFF4B5563), height: 1.5, fontSize: 13)),
        const SizedBox(height: 14),
      ],

      // ── 5. PRICE BLOCK (modern: highlighted card, price dominates, MRP+discount inline)
      Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14181B) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text('₹${price.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
              Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('₹${strike.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(100)), child: Text('$discountPct% OFF', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
              Text('₹${(price * qty).toStringAsFixed(0)} total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.local_offer_outlined, size: 12, color: const Color(0xFF00A63E)),
            const SizedBox(width: 4),
            Expanded(child: Text('Inclusive of taxes • Free delivery over ₹499 • EMI from ₹${(price / 3).toStringAsFixed(0)}/mo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : const Color(0xFF6B7280)))),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      // ── 6. VARIANT SELECTOR (pack size) — chips with price hint
      if (variants.length > 1) ...[
        Row(children: [
          Text('Pack size', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
          const Spacer(),
          Text('Selected: $variantLabel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF00A63E))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(variants.length, (i) {
          final v = variants[i];
          final sel = i == selectedVariant;
          final vPrice = (v['price'] as double).toStringAsFixed(0);
          return ChoiceChip(
            label: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(v['label'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: sel ? Colors.white : (isDark ? Colors.white : const Color(0xFF0B0E0F)))),
              if (!sel) Text('₹$vPrice', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : const Color(0xFF9CA3AF))),
            ]),
            selected: sel,
            showCheckmark: false,
            selectedColor: const Color(0xFF0B0E0F),
            backgroundColor: isDark ? const Color(0xFF1A1F24) : Colors.white,
            side: BorderSide(color: sel ? const Color(0xFF0B0E0F) : const Color(0xFFE5E7EB), width: sel ? 1.4 : 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (_) { HapticFeedback.selectionClick(); onVariant(i); },
          );
        })),
        const SizedBox(height: 16),
      ],

      // ── 7. QUANTITY + MOQ + PRIMARY ACTIONS (grouped, modern e-comm standard)
      Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Quantity', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFFFDE68A))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inventory_2_rounded, size: 11, color: Color(0xFFD97706)), const SizedBox(width: 4), Text('Min. $moq pcs', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E)))])),
          Text('MOQ: $moq units', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
        ],
      ),
      const SizedBox(height: 8),
      Row(children: [
        Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(children: [
            IconButton(onPressed: qty > moq ? () { HapticFeedback.selectionClick(); onQty(qty - 1); } : null, icon: const Icon(Icons.remove_rounded, size: 18), visualDensity: VisualDensity.compact),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
            IconButton(onPressed: qty < 99 ? () { HapticFeedback.selectionClick(); onQty(qty + 1); } : null, icon: const Icon(Icons.add_rounded, size: 18), visualDensity: VisualDensity.compact),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100)), child: Text('In stock • Ships today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)))))),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Icon(Icons.info_outline_rounded, size: 12, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Expanded(child: Text('Minimum order quantity is $moq ${moq == 1 ? 'unit' : 'units'} • Add at least $moq to cart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : const Color(0xFF6B7280)))),
      ]),
      const SizedBox(height: 14),

      // Primary actions — Add to cart + Buy now (always visible, sticky on mobile via _StickyBuyBar)
      if (isWide) ...[
        Row(children: [
          Expanded(child: ScaleTransition(scale: Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: addAnim, curve: Curves.easeOut)), child: OutlinedButton.icon(onPressed: () => onAdd(buyNow: false), icon: const Icon(Icons.shopping_bag_outlined, size: 18), label: const Text('Add to cart'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFF0B0E0F)), foregroundColor: const Color(0xFF0B0E0F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), textStyle: const TextStyle(fontWeight: FontWeight.w800))))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: () => onAdd(buyNow: true), icon: const Icon(Icons.bolt_rounded, size: 18), label: const Text('Buy now'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), textStyle: const TextStyle(fontWeight: FontWeight.w800)))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () { CartStore.instance.toggleWishlist(product.id); HapticFeedback.lightImpact(); }, icon: Icon(CartStore.instance.isWishlisted(product.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: CartStore.instance.isWishlisted(product.id) ? const Color(0xFFEF4444) : const Color(0xFF6B7280)), label: Text(CartStore.instance.isWishlisted(product.id) ? 'Wishlisted' : 'Wishlist'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: isDark ? const Color(0xFF2A2E32) : const Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: () { HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share: ${product.name}'), behavior: SnackBarBehavior.floating)); }, icon: const Icon(Icons.share_outlined, size: 16), label: const Text('Share'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: isDark ? const Color(0xFF2A2E32) : const Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))))),
        ]),
        const SizedBox(height: 14),
      ] else ...[
        // Mobile: wishlist/share inline below qty, actions are sticky bar so show only secondary
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () { CartStore.instance.toggleWishlist(product.id); HapticFeedback.lightImpact(); }, icon: Icon(CartStore.instance.isWishlisted(product.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: CartStore.instance.isWishlisted(product.id) ? const Color(0xFFEF4444) : null), label: Text(CartStore.instance.isWishlisted(product.id) ? 'Wishlisted' : 'Wishlist'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11), side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: () { HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share: ${product.name}'), behavior: SnackBarBehavior.floating)); }, icon: const Icon(Icons.share_outlined, size: 16), label: const Text('Share'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11), side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))))),
        ]),
        const SizedBox(height: 14),
      ],

      // ── 8. ASSURANCE ROW (modern trust strip — 4 columns)
      _AssuranceRow(isDark: isDark),
      const SizedBox(height: 12),

      // ── 9. DELIVERY CARD (secondary, below assurance)
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.local_shipping_rounded, size: 18, color: Color(0xFF00A63E))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Delivery in 2–4 days • Free over ₹499', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text('Dispatched within 24h from Varanasi • COD available', style: theme.textTheme.labelSmall?.copyWith(color: Colors.black54, fontSize: 11)),
          ])),
          Icon(Icons.verified_rounded, size: 18, color: const Color(0xFF00C805).withOpacity(0.9)),
        ]),
      ),
      const SizedBox(height: 18),

      // ── 10. DETAILS TABS (expandable, modern accordion)
      ...[
        _ExpTile(title: 'Product details', expanded: expanded['details']!, onToggle: () => onToggle('details'), child: Text(product.description != null ? '${product.description!}\n\n• 100% organic sugarcane, wood-pressed\n• No sulphur, no chemicals, no refined sugar\n• Rich in iron & minerals\n• Hygienic pouch/jar pack' : 'Pure jaggery details', style: theme.textTheme.bodySmall?.copyWith(height: 1.5, color: Colors.black87))),
        _ExpTile(title: 'Benefits', expanded: expanded['benefits']!, onToggle: () => onToggle('benefits'), child: Text('• Natural iron (12mg/100g)\n• Better digestion vs white sugar\n• Slow energy release\n• Ayurvedic warming properties', style: theme.textTheme.bodySmall?.copyWith(height: 1.5))),
        _ExpTile(title: 'Ingredients & storage', expanded: expanded['ingredients']!, onToggle: () => onToggle('ingredients'), child: Text('Ingredients: Organic sugarcane juice only.\nStorage: Cool, dry place. Reseal after opening. Best before 9 months.', style: theme.textTheme.bodySmall?.copyWith(height: 1.5))),
        _ExpTile(title: 'Shipping & returns', expanded: expanded['shipping']!, onToggle: () => onToggle('shipping'), child: Text('• Ships within 24h (Varanasi)\n• Delhivery / Blue Dart / India Post\n• 7-day return if pack is intact\n• Free shipping over ₹499', style: theme.textTheme.bodySmall?.copyWith(height: 1.5))),
      ],
    ]);
  }
}

class _AssuranceRow extends StatelessWidget {
  const _AssuranceRow({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.local_shipping_outlined, 'Free delivery', 'Over ₹499'),
      (Icons.payments_outlined, 'COD', 'Pay on delivery'),
      (Icons.lock_outline_rounded, 'Secure', 'SSL + UPI'),
      (Icons.science_outlined, 'Lab tested', 'QR report'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: items.map((e) {
        final icon = e.$1; final title = e.$2; final sub = e.$3;
        return Expanded(child: Column(children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: const Color(0xFF0B0E0F))),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0B0E0F)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(sub, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]));
      }).toList()),
    );
  }
}

class _ExpTile extends StatelessWidget {
  const _ExpTile({required this.title, required this.expanded, required this.onToggle, required this.child});
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), trailing: Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded), onTap: onToggle, dense: true, visualDensity: VisualDensity.compact),
        AnimatedCrossFade(firstChild: const SizedBox.shrink(), secondChild: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: child), crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst, duration: const Duration(milliseconds: 220)),
      ]),
    );
  }
}

class _RelatedStrip extends StatelessWidget {
  const _RelatedStrip({required this.related, required this.isDark, required this.onTap});
  final List<Product> related;
  final bool isDark;
  final ValueChanged<Product> onTap;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('You may also like', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      SizedBox(height: 148, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: related.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) {
        final p = related[i];
        return InkWell(
          onTap: () => onTap(p),
          borderRadius: BorderRadius.circular(14),
          child: Container(width: 132, decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))), padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Container(decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)), clipBehavior: Clip.antiAlias, child: p.imageAsset != null ? Image.asset(p.imageAsset!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Icon(p.imagePlaceholder, color: const Color(0xFF00C805))) : Icon(p.imagePlaceholder, color: const Color(0xFF00C805)))),
            const SizedBox(height: 6),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            Text('₹${p.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF00A63E))),
          ])),
        );
      })),
    ]);
  }
}

class _StickyBuyBar extends StatelessWidget {
  const _StickyBuyBar({required this.price, required this.qty, required this.moq, required this.addAnim, required this.onAdd, required this.onBuy, required this.isDark});
  final double price;
  final int qty;
  final int moq;
  final AnimationController addAnim;
  final VoidCallback onAdd;
  final VoidCallback onBuy;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final total = price * qty;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom * 0.4),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, border: Border(top: BorderSide(color: const Color(0xFFE5E7EB))), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -6))]),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          Text('₹${price.toStringAsFixed(0)} × $qty', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          if (moq > 1) Text('Min $moq pcs', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
        ]),
        const SizedBox(width: 12),
        Expanded(child: ScaleTransition(scale: Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: addAnim, curve: Curves.easeOut)), child: OutlinedButton(onPressed: onAdd, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Color(0xFF0B0E0F)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))), child: const Text('Add to cart', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F)))))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: onBuy, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))), child: const Text('Buy now', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)))),
      ]),
    );
  }
}
