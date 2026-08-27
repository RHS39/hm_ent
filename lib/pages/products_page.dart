import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../services/product_store.dart';
import '../services/scroll_manager.dart';
import '../appwrite/appwrite_client.dart';
import '../appwrite/product_repository.dart';
import 'package:go_router/go_router.dart';

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

/// Simple product model for demo.
class Product {
  const Product({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.imagePlaceholder,
    this.description,
    this.imageAsset,
    this.image1,
    this.image2,
    this.image3,
    this.moq = 2,
  });

  final String id;
  final String productId; // 2-digit display ID like "01", "02"
  final String name;
  final double price;
  final IconData imagePlaceholder;
  final String? description;
  final String? imageAsset;
  final String? image1;
  final String? image2;
  final String? image3;
  final int moq;

  /// All images (asset fallbacks + Appwrite URLs)
  List<String> get allImages {
    final imgs = <String>[];
    if (image1 != null && image1!.isNotEmpty) imgs.add(image1!);
    if (image2 != null && image2!.isNotEmpty) imgs.add(image2!);
    if (image3 != null && image3!.isNotEmpty) imgs.add(image3!);
    if (imageAsset != null && imageAsset!.isNotEmpty) imgs.add(imageAsset!);
    return imgs;
  }
}

/// Products listing page – now backed by Appwrite with local fallback.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const List<Product> _fallbackProducts = [
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

  List<Product> _allProducts = _fallbackProducts;
  String _query = '';
  String _sort = 'Featured';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Load from Appwrite immediately on page init
    _loadFromAppwrite();
  }

  Future<void> _loadFromAppwrite() async {
    if (_loaded) return;
    try {
      // Use ProductStore as single source of truth
      if (!ProductStore.instance.loaded) {
        await ProductStore.instance.load();
      }
      final store = ProductStore.instance;
      if (store.products.isNotEmpty && mounted) {
        final mapped = store.products.map((r) {
          final price = r['price'] is num ? (r['price'] as num).toDouble() : double.tryParse('${r['price']}') ?? 0;
          final name = '${r['name']}';
          final productId = '${r['product_id']}';
          return Product(
            id: '${r['id']}',
            productId: productId.isNotEmpty ? productId : '00',
            name: name,
            price: price,
            description: r['description'] as String?,
            imagePlaceholder: _iconFromName('${r['icon']}'),
            imageAsset: _assetForName(name),
            // FIX PGRST204: canonical image_url with legacy fallback, null-safe
            // FIX PGRST204: use canonical image_url only
            image1: (r['image_url'] ?? r['image']) as String?,
            image2: r['image_2'] as String?,
            image3: r['image_3'] as String?,
            moq: (int.tryParse('${r['moq'] ?? r['minimum_order_quantity'] ?? 2}') ?? 2).clamp(1, 99),
          );
        }).toList();
        // Sort by Appwrite price (default: low to high)
        mapped.sort((a, b) => a.price.compareTo(b.price));
        if (mapped.isNotEmpty) {
          setState(() {
            _allProducts = mapped;
            _loaded = true;
          });
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

  List<Product> get _filtered {
    var list = _allProducts.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();
    switch (_sort) {
      case 'Price: Low to High':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Name':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Hari Om Traders', subtitle: 'Products • hariomtraders.com'),
      body: ProductsContent(
        products: _filtered,
        query: _query,
        sort: _sort,
        onQueryChanged: (v) {
          setState(() => _query = v);
        },
        onSortChanged: (v) {
          setState(() => _sort = v);
        },
      ),
    );
  }
}

/// Content-only version — ORGANIC THEME matched to home page
/// Palette: #00C805 primary, #0B0E0F ink, #FFF7ED warm, white cards, 16-20 radius, soft shadows
class ProductsContent extends StatefulWidget {
  const ProductsContent({
    super.key,
    required this.products,
    required this.query,
    required this.sort,
    required this.onQueryChanged,
    required this.onSortChanged,
  });

  final List<Product> products;
  final String query;
  final String sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSortChanged;

  @override
  State<ProductsContent> createState() => _ProductsContentState();
}

class _ProductsContentState extends State<ProductsContent> with SingleTickerProviderStateMixin {
  String _category = 'All';
  bool _isGrid = true;
  static const _categories = ['All', 'Pouches', 'Chikki', 'Syrup & Kakvi', 'Blocks', 'Spiced', 'Gifting'];
  static const List<int> _pageSizeOptions = [8, 12, 24];
  int _itemsPerPage = 12;
  int _currentPage = 0; // 0-indexed, URL is 1-indexed
  int _totalProducts = 0;
  List<Product> _serverProducts = [];
  bool _loading = false;
  String? _error;
  late AnimationController _entrance;
  bool _syncingUrl = false;
  static const _scrollKey = 'products';
  late final ScrollController _scrollCtrl;

  bool get _isServerMode => AppwriteService.isInitialized;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _scrollCtrl = ScrollManager.instance.controllerFor(_scrollKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromUrl();
      _fetch();
      // restore scroll offset after frame — browser back should land at same spot
      if (_scrollCtrl.hasClients) {
        final saved = ScrollManager.instance.getOffset(_scrollKey);
        if (saved > 0 && (_scrollCtrl.offset - saved).abs() > 1) {
          _scrollCtrl.jumpTo(saved.clamp(0, _scrollCtrl.position.maxScrollExtent));
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep URL in sync if query params changed externally
  }

  void _syncFromUrl() {
    try {
      final uri = GoRouterState.of(context).uri;
      final qp = uri.queryParameters;
      final p = int.tryParse(qp['page'] ?? '');
      final l = int.tryParse(qp['limit'] ?? '');
      bool changed = false;
      if (p != null && p >= 1 && p != _currentPage + 1) {
        _currentPage = p - 1;
        changed = true;
      }
      if (l != null && _pageSizeOptions.contains(l) && l != _itemsPerPage) {
        _itemsPerPage = l;
        changed = true;
      }
      if (changed && mounted) setState(() {});
    } catch (_) {}
  }

  void _syncToUrl() {
    if (_syncingUrl) return;
    try {
      final uri = GoRouterState.of(context).uri;
      final currentPageStr = uri.queryParameters['page'];
      final currentLimitStr = uri.queryParameters['limit'];
      final desiredPage = (_currentPage + 1).toString();
      final desiredLimit = _itemsPerPage.toString();
      if (currentPageStr == desiredPage && currentLimitStr == desiredLimit) return;
      _syncingUrl = true;
      final newQuery = Map<String, String>.from(uri.queryParameters);
      newQuery['page'] = desiredPage;
      newQuery['limit'] = desiredLimit;
      final newUri = uri.replace(queryParameters: newQuery);
      GoRouter.of(context).go(newUri.toString());
    } catch (_) {
    } finally {
      Future.delayed(const Duration(milliseconds: 100), () => _syncingUrl = false);
    }
  }

  String _sortToField(String sort) {
    switch (sort) {
      case 'Price: Low to High':
        return 'price';
      case 'Price: High to Low':
        return 'price';
      case 'Name':
        return 'name';
      default:
        return 'product_id';
    }
  }

  bool _sortAscending(String sort) {
    if (sort == 'Price: High to Low') return false;
    return true;
  }

  Future<void> _fetch() async {
    if (!_isServerMode) {
      // Client mode uses widget.products directly; keep total in sync
      _totalProducts = _visibleClient.length;
      _serverProducts = [];
      _loading = false;
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final offset = _currentPage * _itemsPerPage;
    final sortField = _sortToField(widget.sort);
    final asc = _sortAscending(widget.sort);
    // Trigger fetch when page or itemsPerPage changes (useEffect equivalent)
    try {
      final res = await AppwriteProductRepository.fetchProductsPaginated(
        limit: _itemsPerPage,
        offset: offset,
        category: _category,
        searchQuery: widget.query,
        sortBy: sortField,
        ascending: asc,
      );
      if (!mounted) return;
      final mapped = res.items.map((r) {
        final price = r['price'] is num ? (r['price'] as num).toDouble() : double.tryParse('${r['price']}') ?? 0;
        final name = '${r['name']}';
        final productId = '${r['product_id']}';
        return Product(
          id: '${r['id']}',
          productId: productId.isNotEmpty ? productId : '00',
          name: name,
          price: price,
          description: r['description'] as String?,
          imagePlaceholder: _iconFromName('${r['icon']}'),
          imageAsset: _assetForName(name),
          image1: (r['image_url'] ?? r['image']) as String?,
          image2: r['image_2'] as String?,
          image3: r['image_3'] as String?,
          moq: (int.tryParse('${r['moq'] ?? r['minimum_order_quantity'] ?? 2}') ?? 2).clamp(1, 99),
        );
      }).toList();
      setState(() {
        _serverProducts = mapped;
        _totalProducts = res.total;
        _loading = false;
      });
      _syncToUrl();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Helper to get asset for name (duplicate from parent for server mapping)
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
    _entrance.dispose();
    super.dispose();
  }

  bool _matchesCategory(Product p) {
    final n = p.name.toLowerCase();
    switch (_category) {
      case 'Pouches':
        return n.contains('powder') || n.contains('granular') || n.contains('gud') || n.contains('cubes');
      case 'Chikki':
        return n.contains('chikki');
      case 'Syrup & Kakvi':
        return n.contains('syrup') || n.contains('kakvi') || n.contains('liquid');
      case 'Blocks':
        return n.contains('block') || n.contains('cubes');
      case 'Spiced':
        return n.contains('ginger') || n.contains('moringa') || n.contains('turmeric') || n.contains('cardamom') || n.contains('tea');
      case 'Gifting':
        return n.contains('hamper') || n.contains('gift');
      default:
        return true;
    }
  }

  // Client-side filtered (fallback when Appwrite offline)
  List<Product> get _visibleClient => widget.products.where(_matchesCategory).toList();

  // Server-side: _serverProducts is already paginated, _totalProducts is total
  List<Product> get _visible => _isServerMode ? _serverProducts : _visibleClient;

  List<Product> get _paginated {
    if (_isServerMode) return _serverProducts; // already page-sized from server
    final v = _visibleClient;
    final start = _currentPage * _itemsPerPage;
    if (start >= v.length) return [];
    return v.skip(start).take(_itemsPerPage).toList();
  }

  int get _totalPages => _isServerMode
      ? (_totalProducts / _itemsPerPage).ceil().clamp(1, 999)
      : (_visibleClient.length / _itemsPerPage).ceil().clamp(1, 999);

  int get _effectiveTotal => _isServerMode ? _totalProducts : _visibleClient.length;

  void _goToPage(int page) {
    final clamped = page.clamp(0, _totalPages - 1);
    if (clamped == _currentPage) return;
    setState(() => _currentPage = clamped);
    _fetch();
  }

  void _resetPage() {
    if (_currentPage != 0) {
      setState(() => _currentPage = 0);
      _fetch();
    } else {
      _fetch();
    }
  }

  void _changeItemsPerPage(int? v) {
    if (v == null || !_pageSizeOptions.contains(v)) return;
    setState(() {
      _itemsPerPage = v;
      _currentPage = 0;
    });
    _fetch();
  }

  @override
  void didUpdateWidget(covariant ProductsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query || oldWidget.sort != widget.sort || oldWidget.products.length != widget.products.length) {
      _resetPage();
    } else if (_isServerMode && oldWidget.query == widget.query && oldWidget.sort == widget.sort) {
      // No-op: server fetch already handled via _resetPage
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB);
    const maxW = 1180.0;

    return Container(
      color: bg,
      child: CustomScrollView(
        key: const PageStorageKey<String>(_scrollKey),
        controller: _scrollCtrl,
        slivers: [
          // ── Organic banner — matches home _TrustBar / _HeroSection palette ──
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxW),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14181B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(100)),
                        child: const Text('FREE SHIPPING', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Free delivery over ₹499 • Lab-tested • 48h dispatch from Varanasi', style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white70 : const Color(0xFF374151), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      Icon(Icons.verified_rounded, size: 16, color: const Color(0xFF00C805).withOpacity(0.9)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          // ── Header — same typography as home _SectionHeader ──
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxW),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: LayoutBuilder(builder: (context, c) {
                    final isNarrow = c.maxWidth < 720;
                    final titleCol = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Wrap(spacing: 8, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2620) : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF2A3A2E) : const Color(0xFFD1FAE5))),
                          child: Text('15 PRODUCTS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.8, color: const Color(0xFF00A63E))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF0B0E0F), borderRadius: BorderRadius.circular(100)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFB020)), const SizedBox(width: 4), Text('4.8 • 10k+ families', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10))]),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text('Shop organic jaggery', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.7, fontSize: c.maxWidth < 360 ? 22 : 26, color: isDark ? Colors.white : const Color(0xFF0B0E0F), height: 1.05)),
                      const SizedBox(height: 4),
                      Text('Wood-pressed • No sulphur • Iron-rich • Direct from farm', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 12)),
                    ]);
                    final search = ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: TextField(
                        onChanged: widget.onQueryChanged,
                        decoration: InputDecoration(
                          hintText: 'Search powder, chikki, kakvi…',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: widget.query.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => widget.onQueryChanged('')) : null,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF14181B) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.4)),
                        ),
                      ),
                    );
                    if (isNarrow) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [titleCol, const SizedBox(height: 12), search]);
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: titleCol), const SizedBox(width: 16), search]);
                  }),
                ),
              ),
            ),
          ),
          // ── Filters — organic pill style matching home bento ──
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxW),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14181B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final c in _categories) ...[
                            ChoiceChip(
                              label: Text(c),
                              selected: _category == c,
                              onSelected: (_) { setState(() { _category = c; _currentPage = 0; }); _fetch(); },
                              showCheckmark: false,
                              labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _category == c ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF374151))),
                              selectedColor: const Color(0xFF0B0E0F),
                              backgroundColor: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB),
                              side: BorderSide(color: _category == c ? const Color(0xFF0B0E0F) : (isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(_isServerMode ? '${_paginated.length} of $_totalProducts • Page ${_currentPage+1}/$_totalPages' : '${_visible.isEmpty ? 0 : _paginated.length} of ${_visible.length} • Page ${_currentPage+1}/$_totalPages',
                              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
                          Container(width: 1, height: 14, color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                          // Items per page selector (MUI Select equivalent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _itemsPerPage,
                                isDense: true,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0B0E0F)),
                                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                                items: _pageSizeOptions.map((n) => DropdownMenuItem(value: n, child: Text('$n / page'))).toList(),
                                onChanged: _changeItemsPerPage,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: widget.onSortChanged,
                            offset: const Offset(0, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'Featured', child: Text('Featured')),
                              PopupMenuItem(value: 'Name', child: Text('Name A–Z')),
                              PopupMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
                              PopupMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.swap_vert_rounded, size: 12, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(widget.sort,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                              ]),
                            ),
                          ),
                          _SegmentToggle(
                            isGrid: _isGrid,
                            isDark: isDark,
                            onGrid: () => setState(() => _isGrid = true),
                            onList: () => setState(() => _isGrid = false),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          // ── Grid / List — organic cards ──
          // Loading indicator (MUI CircularProgress equivalent)
          if (_loading && _visible.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxW),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFF00C805))),
                    ),
                  ),
                ),
              ),
            ),
          if (_error != null && _visible.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxW),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                      child: Column(children: [
                        const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFDC2626)),
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Retry'), style: FilledButton.styleFrom(backgroundColor: Color(0xFF0B0E0F))),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final viewportW = constraints.crossAxisExtent;
              final effectiveW = viewportW > maxW + 32 ? maxW : viewportW - 32;
              final hPad = viewportW > maxW + 32 ? (viewportW - maxW) / 2 : 16.0;
              if (_loading && _visible.isNotEmpty) {
                // Show overlay CircularProgress while fetching new page
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: const Color(0xFF00C805)),
                    ),
                  ),
                );
              }
              if (_visible.isEmpty && !_loading) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: maxW),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                          child: Column(children: [
                            Icon(Icons.search_off_rounded, size: 36, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                            const SizedBox(height: 10),
                            Text('No products found', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
                            const SizedBox(height: 6),
                            Text('Try another search or category', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                            const SizedBox(height: 14),
                            FilledButton(onPressed: () { widget.onQueryChanged(''); setState(() => _category = 'All'); }, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F)), child: const Text('Clear filters')),
                          ]),
                        ),
                      ),
                    ),
                  ),
                );
              }
              final isList = !_isGrid;
              if (isList) {
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 18),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OrganicCard(product: _paginated[i], isDark: isDark, isList: true, index: i, entrance: _entrance),
                      ),
                      childCount: _paginated.length,
                    ),
                  ),
                );
              }
              final int cross;
              const double spacing = 12;
              if (effectiveW >= 1100) cross = 4;
              else if (effectiveW >= 760) cross = 3;
              else if (effectiveW >= 520) cross = 2;
              else if (effectiveW >= 360) cross = 2;
              else cross = 1;
              final cardW = (effectiveW - spacing * (cross - 1)) / cross;
              final imageH = cardW * 1.02;
              final infoH = 86 + cardW * 0.18;
              double aspect = cardW / (imageH + infoH);
              aspect = aspect.clamp(0.52, 0.72);
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross, childAspectRatio: aspect, crossAxisSpacing: spacing, mainAxisSpacing: spacing),
                  delegate: SliverChildBuilderDelegate((context, i) => _OrganicCard(product: _paginated[i], isDark: isDark, index: i, entrance: _entrance), childCount: _paginated.length),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxW),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                    child: Row(children: [
                      Icon(Icons.verified_rounded, size: 16, color: const Color(0xFF00C805)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('All jaggery • NPOP certified • Lab-tested • Wood-pressed in Varanasi', style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white70 : const Color(0xFF6B7280), fontWeight: FontWeight.w600))),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  const _SegmentToggle({required this.isGrid, required this.isDark, required this.onGrid, required this.onList});
  final bool isGrid;
  final bool isDark;
  final VoidCallback onGrid;
  final VoidCallback onList;
  @override
  Widget build(BuildContext context) {
    const double trackW = 72;
    const double trackH = 36;
    const double gap = 3;
    const double thumbW = (trackW - gap * 2) / 2;
    final bool selectedGrid = isGrid;
    return GestureDetector(
      onTap: selectedGrid ? onList : onGrid,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: trackW,
        height: trackH,
        padding: const EdgeInsets.all(gap),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2328) : const Color(0xFFF0F1F3),
          borderRadius: BorderRadius.circular(trackH),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: selectedGrid ? 0 : thumbW + gap,
              top: 0,
              width: thumbW,
              height: trackH - gap * 2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0B0E0F),
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: selectedGrid ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.view_list_rounded,
                      size: 16,
                      color: !selectedGrid ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



/// Organic card — warm palette matching home _ModernFeatureCard / _FeaturedCarousel
class _OrganicCard extends StatefulWidget {
  const _OrganicCard({required this.product, required this.isDark, required this.index, required this.entrance, this.isList = false});
  final Product product;
  final bool isDark;
  final int index;
  final AnimationController entrance;
  final bool isList;

  @override
  State<_OrganicCard> createState() => _OrganicCardState();
}

class _OrganicCardState extends State<_OrganicCard> {
  bool _liked = false;

  String _altAsset(String path) {
    if (path.endsWith('.png')) return path.replaceAll('.png', '.jpg');
    if (path.endsWith('.jpg')) return path.replaceAll('.jpg', '.png');
    return path;
  }

  bool _isNetworkUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

  String? get _displayImage {
    // Prefer Appwrite storage network URL (image1/2/3) over local asset fallback
    final all = widget.product.allImages;
    if (all.isEmpty) return null;
    for (final u in all) {
      if (_isNetworkUrl(u)) return u;
    }
    for (final u in all) {
      if (u.startsWith('assets/')) return u;
    }
    return all.first;
  }

  Widget _buildAssetImage(String asset) {
    return Image.asset(asset, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) {
      final alt = _altAsset(asset);
      if (alt != asset) return Image.asset(alt, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => _fallback());
      return _fallback();
    });
  }

  Widget _buildResolvedImage(String? url) {
    if (url == null || url.isEmpty) return _fallback();
    if (_isNetworkUrl(url)) {
      return Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
          loadingBuilder: (c, ch, p) => p == null ? ch : Container(color: const Color(0xFF00C805).withOpacity(0.08), child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C805))))),
          errorBuilder: (_, __, ___) {
            // On network failure, fallback to local asset if available
            final assetFallback = widget.product.imageAsset;
            if (assetFallback != null && assetFallback.isNotEmpty) return _buildAssetImage(assetFallback);
            return _fallback();
          });
    }
    return _buildAssetImage(url);
  }

  Widget _fallback() => Container(color: widget.isDark ? const Color(0xFF1F2429) : const Color(0xFFF3F4F6), child: Center(child: Icon(widget.product.imagePlaceholder, size: 36, color: const Color(0xFF00C805).withOpacity(0.85))));

  bool get isDark => widget.isDark;
  bool get _isBestseller => widget.product.id == '1' || widget.product.id == '9' || widget.product.name.toLowerCase().contains('gud');
  bool get _isNew => widget.product.id == '5' || widget.product.id == '14';
  double get _mrp => widget.product.price * 1.18;
  String get _weight {
    final m = RegExp(r'(\d+(\.\d+)?\s?(g|kg|ml)\b)', caseSensitive: false).firstMatch(widget.product.name);
    return m?.group(0)?.toUpperCase() ?? '';
  }

  Color _bgFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('chikki')) return const Color(0xFFFEF3C7);
    if (n.contains('kakvi') || n.contains('syrup') || n.contains('liquid')) return const Color(0xFFEFF6FF);
    if (n.contains('tea')) return const Color(0xFFFEFCE8);
    if (n.contains('hamper') || n.contains('gift')) return const Color(0xFFFAF5FF);
    if (n.contains('ginger') || n.contains('turmeric') || n.contains('moringa') || n.contains('cardamom')) return const Color(0xFFECFDF5);
    return const Color(0xFFFFF7ED);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delay = (widget.index * 0.04).clamp(0.0, 0.4);
    final anim = CurvedAnimation(parent: widget.entrance, curve: Interval(delay, (delay + 0.5).clamp(0, 1), curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(opacity: anim.value, child: Transform.translate(offset: Offset(0, 12 * (1 - anim.value)), child: child)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14181B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.18 : 0.06), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            try {
              context.push('/product/${widget.product.id}', extra: widget.product);
            } catch (_) {
              GoRouter.of(context).go('/product/${widget.product.id}?title=${Uri.encodeComponent(widget.product.name)}');
            }
          },
          child: widget.isList ? _buildList(theme) : _buildGrid(theme),
        ),
      ),
    );
  }

  Widget _buildGrid(ThemeData theme) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final inset = (w * 0.042).clamp(7.0, 10.0);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(
          aspectRatio: 1.04,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: _bgFor(widget.product.name), child: _buildResolvedImage(_displayImage)),
            Positioned(
              top: inset, left: inset,
              child: Row(children: [
                if (_isBestseller) Container(padding: EdgeInsets.symmetric(horizontal: (w * 0.036).clamp(6, 8), vertical: (w * 0.015).clamp(2, 3.5)), decoration: BoxDecoration(color: const Color(0xFF0B0E0F), borderRadius: BorderRadius.circular(100)), child: Text('BESTSELLER', style: TextStyle(color: Colors.white, fontSize: (w * 0.042).clamp(7.5, 9), fontWeight: FontWeight.w800))),
                if (_isNew) ...[SizedBox(width: w * 0.03), Container(padding: EdgeInsets.symmetric(horizontal: (w * 0.036).clamp(6, 8), vertical: (w * 0.015).clamp(2, 3.5)), decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(100)), child: Text('NEW', style: TextStyle(color: Colors.white, fontSize: (w * 0.042).clamp(7.5, 9), fontWeight: FontWeight.w800)))],
              ]),
            ),
            Positioned(
              top: inset, right: inset,
              child: InkWell(
                onTap: () => setState(() => _liked = !_liked),
                borderRadius: BorderRadius.circular(100),
                child: Container(width: (w * 0.15).clamp(26, 30), height: (w * 0.15).clamp(26, 30), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: w * 0.04)]), child: Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: (w * 0.078).clamp(13, 16), color: _liked ? const Color(0xFFEF4444) : const Color(0xFF6B7280))),
              ),
            ),
            if (_weight.isNotEmpty) Positioned(bottom: inset, left: inset, child: Container(padding: EdgeInsets.symmetric(horizontal: (w * 0.036).clamp(6, 8), vertical: (w * 0.015).clamp(2, 3.5) + 0.5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.96), borderRadius: BorderRadius.circular(100)), child: Text(_weight, style: TextStyle(fontSize: (w * 0.048).clamp(8.5, 10), fontWeight: FontWeight.w800, color: const Color(0xFF0B0E0F))))),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB((w * 0.055).clamp(9, 11), (w * 0.038).clamp(7, 9), (w * 0.055).clamp(9, 11), (w * 0.038).clamp(7, 9)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (int i = 0; i < 5; i++) Icon(Icons.star_rounded, size: (w * 0.048).clamp(7.5, 9), color: const Color(0xFFFFB020)),
                    const SizedBox(width: 3),
                    Flexible(child: Text('4.8', overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: (w * 0.045).clamp(7.5, 9), color: isDark ? Colors.white70 : const Color(0xFF111827)))),
                    if (w >= 105) ...[
                      SizedBox(width: w * 0.012),
                      Flexible(child: Text('(1.2k)', overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(fontSize: (w * 0.045).clamp(7, 8.5), color: const Color(0xFF9CA3AF)))),
                    ],
                  ]),
                ),
                const SizedBox(width: 4),
                if (w >= 130)
                  Flexible(
                    child: Container(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.022, vertical: w * 0.008),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFFD1FAE5), width: 0.6)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.verified_rounded, size: (w * 0.042).clamp(7, 9), color: const Color(0xFF00A63E)),
                          SizedBox(width: w * 0.01),
                          Flexible(child: Text('Organic', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: (w * 0.036).clamp(6.5, 7.5), fontWeight: FontWeight.w800, color: const Color(0xFF00A63E)))),
                        ])),
                  ),
              ]),
              SizedBox(height: w * 0.025),
              Text(widget.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: (w * 0.069).clamp(11.5, 13), height: 1.2, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
              SizedBox(height: w * 0.016),
              if (widget.product.description != null) Text(widget.product.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontSize: (w * 0.055).clamp(9.5, 10.5), height: 1.35, color: const Color(0xFF6B7280))),
              const Spacer(),
              Row(children: [
                Expanded(
                    child: Row(children: [
                  Flexible(
                    child: Text('₹${widget.product.price.toStringAsFixed(0)}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: (w * 0.072).clamp(11, 13.5), color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
                  ),
                  if (w >= 135) ...[
                    SizedBox(width: w * 0.016),
                    Flexible(
                      child: Text('₹${_mrp.toStringAsFixed(0)}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: (w * 0.045).clamp(7, 9), color: const Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough)),
                    ),
                  ],
                  if (w >= 135) ...[
                    SizedBox(width: w * 0.014),
                    Flexible(
                      child: Container(
                          padding: EdgeInsets.symmetric(horizontal: (w * 0.022).clamp(3, 4), vertical: (w * 0.01).clamp(1, 2)),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(w * 0.025)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('18% OFF', style: TextStyle(fontSize: (w * 0.038).clamp(6, 7.5), fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
                          )),
                    ),
                  ],
                ])),
                const SizedBox(width: 4),
                _OrganicAddBtn(isDark: isDark, parentWidth: w),
              ]),
            ]),
          ),
        ),
      ]);
    });
  }

  Widget _buildList(ThemeData theme) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 132,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: _bgFor(widget.product.name), child: _buildResolvedImage(_displayImage)),
            if (_isBestseller)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF0B0E0F), borderRadius: BorderRadius.circular(100)),
                    child: const Text('BESTSELLER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
              ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
              const SizedBox(height: 4),
              if (widget.product.description != null) Text(widget.product.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.4, color: const Color(0xFF6B7280))),
              const Spacer(),
              Row(children: [
                Text('₹${widget.product.price.toStringAsFixed(0)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
                const SizedBox(width: 6),
                Text('₹${_mrp.toStringAsFixed(0)}', style: theme.textTheme.labelSmall?.copyWith(fontSize: 11, color: const Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough)),
                const Spacer(),
                _OrganicAddBtn(isDark: isDark, parentWidth: 132),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _OrganicAddBtn extends StatelessWidget {
  const _OrganicAddBtn({required this.isDark, required this.parentWidth});
  final bool isDark;
  final double parentWidth;
  @override
  Widget build(BuildContext context) {
    final isCompact = parentWidth < 160;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12, vertical: isCompact ? 6 : 7),
      decoration: BoxDecoration(color: const Color(0xFF0B0E0F), borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shopping_bag_outlined, size: isCompact ? 12 : 13, color: Colors.white),
        SizedBox(width: isCompact ? 4 : 5),
        Text(isCompact ? 'Add' : 'Add', style: TextStyle(fontSize: isCompact ? 11 : 12, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.currentPage, required this.totalPages, required this.totalItems, required this.pageSize, required this.onPageChanged, required this.isDark});
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final start = currentPage * pageSize + 1;
    final end = (currentPage * pageSize + pageSize).clamp(0, totalItems);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.14 : 0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: LayoutBuilder(builder: (context, c) {
        final isNarrow = c.maxWidth < 520;
        final info = Text(
          'Showing ${start}–${end} of ${totalItems}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
        );
        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous',
              onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB),
                side: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(totalPages.clamp(0, 5), (i) {
              // Show window of 5 pages centered on current
              int page;
              if (totalPages <= 5) {
                page = i;
              } else {
                final startPage = (currentPage - 2).clamp(0, totalPages - 5);
                page = startPage + i;
              }
              final selected = page == currentPage;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => onPageChanged(page),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF0B0E0F) : (isDark ? const Color(0xFF1A1F24) : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? const Color(0xFF0B0E0F) : (isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                    ),
                    child: Text(
                      '${page + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF374151))),
                    ),
                  ),
                ),
              );
            }),
            if (totalPages > 5) ...[
              if (currentPage < totalPages - 3) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('…', style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
                InkWell(
                  onTap: () => onPageChanged(totalPages - 1),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1F24) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                    ),
                    child: Text('${totalPages}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF374151))),
                  ),
                ),
              ],
            ],
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Next',
              onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB),
                side: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: info),
              const SizedBox(height: 10),
              Center(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: controls)),
            ],
          );
        }
        return Row(
          children: [
            info,
            const Spacer(),
            controls,
          ],
        );
      }),
    );
  }
}
