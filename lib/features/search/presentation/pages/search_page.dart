import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../cubit/search_cubit.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => SearchCubit()..search(''), child: const _SearchView());
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();
  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitSearch(String q) {
    if (q.trim().isEmpty) return;
    context.read<SearchCubit>().addRecent(q.trim());
    context.read<SearchCubit>().search(q.trim());
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () => context.push('/app/cart'), icon: const Icon(Icons.shopping_bag_outlined)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _focusNode,
            autofocus: true,
            onChanged: (v) => context.read<SearchCubit>().searchDebounced(v),
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              hintText: 'Search jaggery, chikki, kakvi...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); context.read<SearchCubit>().clear(); })
                  : null,
            ),
          ),
        ),
        Expanded(child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            if (state.query.isEmpty) return _buildIdleView(context, state, isDark);
            if (state.status == SearchStatus.loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00C805), strokeWidth: 2));
            if (state.status == SearchStatus.failure) return EmptyState(icon: Icons.error_outline_rounded, title: 'Search failed', subtitle: 'Please try again', actionLabel: 'Retry', onAction: () => context.read<SearchCubit>().search(state.query));
            if (state.status == SearchStatus.empty) return EmptyState(icon: Icons.search_off_rounded, title: 'No results found', subtitle: 'Try different keywords or browse categories', actionLabel: 'Browse products', onAction: () => context.go('/app/categories'));
            return _buildResults(context, state, isDark);
          },
        )),
      ]),
    );
  }

  Widget _buildIdleView(BuildContext context, SearchState state, bool isDark) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      if (state.recentSearches.isNotEmpty) ...[
        Row(children: [
          Text('Recent Searches', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF374151))),
          const Spacer(),
          TextButton(onPressed: () => context.read<SearchCubit>().clearRecent(), child: const Text('Clear all', style: TextStyle(fontSize: 12))),
        ]),
        const SizedBox(height: 4),
        ...state.recentSearches.map((q) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_rounded, size: 20, color: Color(0xFF9CA3AF)),
          title: Text(q, style: const TextStyle(fontSize: 14)),
          trailing: IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => context.read<SearchCubit>().removeRecent(q)),
          onTap: () { _searchCtrl.text = q; _submitSearch(q); },
        )),
        const SizedBox(height: 16),
      ],
      Text('Popular Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF374151))),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: ['Jaggery Powder', 'Peanut Chikki', 'Kakvi Syrup', 'Jaggery Blocks', 'Tea Blend', 'Gift Hamper'].map((c) => ActionChip(label: Text(c, style: const TextStyle(fontSize: 12)), onPressed: () { _searchCtrl.text = c; _submitSearch(c); }, avatar: const Icon(Icons.search_rounded, size: 14))).toList()),
    ]);
  }

  Widget _buildResults(BuildContext context, SearchState state, bool isDark) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          Text('${state.resultCount} result${state.resultCount != 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (_) {},
            itemBuilder: (_) => const [PopupMenuItem(value: 'relevance', child: Text('Relevance')), PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')), PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')), PopupMenuItem(value: 'rating', child: Text('Rating'))],
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : Colors.white, borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.swap_vert_rounded, size: 14), SizedBox(width: 4), Text('Sort', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])),
          ),
        ]),
      ),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: state.results.length,
        itemBuilder: (context, i) {
          final p = state.results[i];
          return _SearchResultCard(product: p, isDark: isDark);
        },
      )),
    ]);
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.product, required this.isDark});
  final dynamic product;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/products/${product.id}', extra: product),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Stack(children: [
            Container(width: double.infinity, color: product.isInStock ? const Color(0xFFFFF7ED) : const Color(0xFFF3F4F6), child: product.images.isNotEmpty && product.images.first.startsWith('assets/') ? Image.asset(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.spa, size: 32, color: const Color(0xFF00C805).withOpacity(0.7))) : product.images.isNotEmpty ? Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 32)) : const Icon(Icons.spa, size: 32)),
            if (product.onSale) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(100)), child: Text('-${product.discountPercent.round()}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 2),
            Row(children: [Icon(Icons.star_rounded, size: 12, color: const Color(0xFFFFB020)), const SizedBox(width: 2), Text('${product.rating.toStringAsFixed(1)} (${product.reviewsCount})', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)))]),
            const SizedBox(height: 4),
            Row(children: [
              Text('₹${product.effectivePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0B0E0F))),
              if (product.onSale) ...[const SizedBox(width: 4), Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough))],
            ]),
          ])),
        ]),
      ),
    );
  }
}
