import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../appwrite/product_repository.dart';

/// Responsive product grid that fetches from Supabase and renders organic-themed
/// product cards. Handles loading, error, and empty states.
///
/// Usage:
/// ```dart
/// const ProductGridView()
/// // or with filters:
/// ProductGridView(category: 'Chikki', searchQuery: 'peanut')
/// ```
class ProductGridView extends StatefulWidget {
  const ProductGridView({
    super.key,
    this.category,
    this.searchQuery,
    this.onAddToCart,
  });

  final String? category;
  final String? searchQuery;

  /// Callback when user taps "Add to Cart". Receives the product.
  final ValueChanged<ProductModel>? onAddToCart;

  @override
  State<ProductGridView> createState() => _ProductGridViewState();
}

class _ProductGridViewState extends State<ProductGridView> {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void didUpdateWidget(covariant ProductGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.searchQuery != widget.searchQuery) {
      _future = _fetch();
    }
  }

  Future<List<ProductModel>> _fetch() async {
    final maps = await AppwriteProductRepository.fetchActiveProducts(
      category: widget.category,
      searchQuery: widget.searchQuery,
    );
    return maps.map((m) => ProductModel.fromJson(m)).toList();
  }

  void _retry() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSkeleton();
        }
        if (snapshot.hasError) {
          return _ErrorState(onRetry: _retry);
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const _EmptyState();
        }
        return _ProductGrid(
          products: products,
          onAddToCart: widget.onAddToCart,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
//  Responsive Grid
// ─────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, this.onAddToCart});
  final List<ProductModel> products;
  final ValueChanged<ProductModel>? onAddToCart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossCount = _crossCount(w);
        const spacing = 14.0;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: 0.72,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: products.length,
          itemBuilder: (context, i) => _ProductCard(
            product: products[i],
            index: i,
            onAddToCart: onAddToCart,
          ),
        );
      },
    );
  }

  /// Returns 5 on ultra-wide, 4 on desktop, 3 on tablet, 2 on mobile, 1 on tiny.
  int _crossCount(double width) {
    if (width >= 1400) return 5;
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 480) return 2;
    return 2;
  }
}

// ─────────────────────────────────────────────────────
//  Product Card
// ─────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.index,
    this.onAddToCart,
  });
  final ProductModel product;
  final int index;
  final ValueChanged<ProductModel>? onAddToCart;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _imgFailed = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Color _bgForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'chikki':
        return const Color(0xFFFEF3C7);
      case 'liquid':
      case 'syrup':
        return const Color(0xFFEFF6FF);
      case 'blend':
        return const Color(0xFFFEFCE8);
      case 'hamper':
        return const Color(0xFFFAF5FF);
      case 'flavored':
        return const Color(0xFFECFDF5);
      default:
        return const Color(0xFFFFF7ED);
    }
  }

  bool _isNetworkUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

  String? get _resolvedImageUrl {
    // Prefer Appwrite network URL first, then asset fallback, using allImages
    final all = widget.product.allImages;
    if (all.isEmpty) return widget.product.imageUrl;
    // Prefer http urls first
    for (final u in all) {
      if (_isNetworkUrl(u)) return u;
    }
    // Then assets
    for (final u in all) {
      if (u.startsWith('assets/')) return u;
    }
    return all.first;
  }

  Widget _buildImage() {
    final url = _resolvedImageUrl;

    if (url != null && url.isNotEmpty && !_imgFailed) {
      if (_isNetworkUrl(url)) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF00C805),
              ),
            );
          },
          errorBuilder: (_, __, ___) {
            if (!_imgFailed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _imgFailed = true);
              });
            }
            // Fallback to asset if network fails and asset exists
            final fallbackAsset = widget.product.allImages.where((e) => e.startsWith('assets/')).isNotEmpty
                ? widget.product.allImages.firstWhere((e) => e.startsWith('assets/'))
                : null;
            if (fallbackAsset != null) {
              return Image.asset(fallbackAsset,
                  fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => _fallbackIcon());
            }
            return _fallbackIcon();
          },
        );
      } else {
        // Asset path (e.g. assets/img/...)
        return Image.asset(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) {
            // Try alt extension (.png <-> .jpg)
            final alt = url.endsWith('.png') ? url.replaceAll('.png', '.jpg') : url.endsWith('.jpg') ? url.replaceAll('.jpg', '.png') : url;
            if (alt != url) {
              return Image.asset(alt, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => _fallbackIcon());
            }
            return _fallbackIcon();
          },
        );
      }
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1F2429) : const Color(0xFFF3F4F6),
      child: Center(
        child: Icon(
          widget.product.placeholderIcon,
          size: 40,
          color: const Color(0xFF00C805).withOpacity(0.85),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.product;
    final delay = (widget.index * 0.06).clamp(0.0, 0.5);
    final anim = CurvedAnimation(
      parent: _anim,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - anim.value)),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14181B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            try {
              context.push('/product/${p.id}', extra: p);
            } catch (_) {
              GoRouter.of(context).go('/product/${p.id}?title=${Uri.encodeComponent(p.name)}');
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image area ──
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: _bgForCategory(p.category),
                      child: _buildImage(),
                    ),
                    // Category tag
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2620) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2A3A2E) : const Color(0xFFD1FAE5),
                          ),
                        ),
                        child: Text(
                          p.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: const Color(0xFF00A63E),
                          ),
                        ),
                      ),
                    ),
                    // Out of stock overlay
                    if (!p.inStock)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // ── Info area ──
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          height: 1.25,
                          color: isDark ? Colors.white : const Color(0xFF0B0E0F),
                        ),
                      ),
                      if (p.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          p.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.5,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Price + Add to Cart
                      Row(
                        children: [
                          Text(
                            p.formattedPrice,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0B0E0F),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: p.inStock ? () => widget.onAddToCart?.call(p) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: p.inStock
                                    ? const Color(0xFF0B0E0F)
                                    : const Color(0xFF9CA3AF),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                          style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Loading Skeleton
// ─────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF14181B) : Colors.white;
    final shimmer = isDark ? const Color(0xFF1E2328) : const Color(0xFFE5E7EB);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cross = w >= 1100 ? 4 : w >= 760 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            childAspectRatio: 0.72,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: cross * 3,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(color: shimmer),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, width: double.infinity, color: shimmer),
                        const SizedBox(height: 6),
                        Container(height: 10, width: 120, color: shimmer),
                        const Spacer(),
                        Container(height: 14, width: 60, color: shimmer),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
//  Error State
// ─────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14181B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: const Color(0xFFEF4444).withOpacity(0.85),
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load products',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0B0E0F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Something went wrong while fetching from the server.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B0E0F),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Empty State
// ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14181B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 40,
                color: isDark ? Colors.white24 : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 12),
              Text(
                'No products found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0B0E0F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try adjusting your search or category filter.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
