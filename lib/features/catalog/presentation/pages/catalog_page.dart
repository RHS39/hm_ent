import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../cubit/catalog_cubit.dart';
import '../widgets/filter_modal.dart';
import '../../data/datasources/catalog_remote_datasource.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/usecases/get_products.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CatalogCubit(GetProducts(CatalogRepositoryImpl(CatalogMockDataSource())))..fetchInitial(),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatefulWidget {
  const _CatalogView();
  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<CatalogCubit>().fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => context.read<CatalogCubit>().updateQuery(v));
  }

  Future<void> _openFilter() async {
    final cubit = context.read<CatalogCubit>();
    final res = await showModalBottomSheet<CatalogFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterModal(initialCategory: cubit.state.category, initialMinPrice: cubit.state.minPrice, initialMaxPrice: cubit.state.maxPrice, initialInStock: cubit.state.inStock, initialMinRating: cubit.state.minRating),
    );
    if (res == null) {
      // clear if user tapped clear? FilterModal returns null on clear - we handle via clear
      return;
    }
    cubit.updateCategory(res.category ?? cubit.state.category);
    cubit.applyFilters(minPrice: res.minPrice, maxPrice: res.maxPrice, inStock: res.inStock, minRating: res.minRating);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Discover', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () => context.push('/app/cart'), icon: const Icon(Icons.shopping_bag_outlined)),
        ],
      ),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) {
          return CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(hintText: 'Search jaggery, chikki, kakvi...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: state.query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); context.read<CatalogCubit>().updateQuery(''); }) : null),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: ['All', 'Pouches', 'Chikki', 'Syrup & Kakvi', 'Blocks', 'Spiced', 'Gifting'].map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c, style: const TextStyle(fontSize: 12)), selected: state.category == c, onSelected: (_) => context.read<CatalogCubit>().updateCategory(c), selectedColor: const Color(0xFF0B0E0F), labelStyle: TextStyle(color: state.category == c ? Colors.white : null, fontWeight: FontWeight.w700)))).toList()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                        child: PopupMenuButton<String>(
                          onSelected: (v) => context.read<CatalogCubit>().updateSort(v),
                          itemBuilder: (_) => const [PopupMenuItem(value: 'Featured', child: Text('Featured')), PopupMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')), PopupMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')), PopupMenuItem(value: 'Popularity', child: Text('Popularity')), PopupMenuItem(value: 'Newest', child: Text('Newest'))],
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.swap_vert_rounded, size: 16), const SizedBox(width: 4), Text(state.sort, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(onPressed: _openFilter, icon: const Icon(Icons.tune_rounded), style: IconButton.styleFrom(backgroundColor: isDark ? const Color(0xFF1A1F24) : Colors.white, side: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)))),
                    ]),
                    const SizedBox(height: 8),
                    if (state.minPrice != null || state.maxPrice != null || state.inStock != null || state.minRating != null)
                      Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 6, children: [if (state.minPrice != null || state.maxPrice != null) Chip(label: Text('₹${state.minPrice?.round() ?? 0} - ₹${state.maxPrice?.round() ?? 1000}')), if (state.inStock != null) const Chip(label: Text('In stock')), if (state.minRating != null) Chip(label: Text('${state.minRating}★+')), ActionChip(label: const Text('Clear'), onPressed: () => context.read<CatalogCubit>().clearFilters())])),
                  ]),
                ),
              ),
              if (state.status == CatalogStatus.loading)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: Color(0xFF00C805))))),
              if (state.status == CatalogStatus.failure)
                SliverToBoxAdapter(child: ErrorState(message: state.error ?? 'Failed to load', onRetry: () => context.read<CatalogCubit>().fetchInitial())),
              if (state.status == CatalogStatus.success && state.products.isEmpty)
                SliverToBoxAdapter(child: EmptyState(icon: Icons.search_off_rounded, title: 'No products found', subtitle: 'Try different keywords or filters', actionLabel: 'Clear filters', onAction: () => context.read<CatalogCubit>().clearFilters())),
              if (state.status == CatalogStatus.success || state.status == CatalogStatus.loadingMore)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      if (i >= state.products.length) return const Center(child: CircularProgressIndicator());
                      final p = state.products[i];
                      return _ProductTile(product: p);
                    }, childCount: state.hasReachedMax ? state.products.length : state.products.length + 1),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final dynamic product;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => context.push('/products/${product.id}', extra: product),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Container(
                width: double.infinity,
                color: product.isInStock ? const Color(0xFFFFF7ED) : const Color(0xFFF3F4F6),
                child: product.images.isNotEmpty && product.images.first.startsWith('assets/')
                    ? Hero(tag: 'product-image-${product.id}', child: Image.asset(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.spa, size: 36, color: const Color(0xFF00C805).withOpacity(0.7))))
                    : product.images.isNotEmpty
                        ? Hero(tag: 'product-image-${product.id}', child: Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 32)))
                        : const Icon(Icons.image, size: 32),
              ),
              if (product.onSale) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(100)), child: Text('-${product.discountPercent.round()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
              if (!product.isInStock) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)), child: const Text('Out of stock', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Row(children: [Icon(Icons.star_rounded, size: 12, color: const Color(0xFFFFB020)), const SizedBox(width: 2), Text('${product.rating.toStringAsFixed(1)} (${product.reviewsCount})', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))]),
              const SizedBox(height: 4),
              Row(children: [
                Text('₹${product.effectivePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0B0E0F))),
                if (product.onSale) ...[const SizedBox(width: 6), Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough))],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
