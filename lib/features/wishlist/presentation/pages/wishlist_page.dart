import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../catalog/domain/entities/product_entity.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../cubit/wishlist_cubit.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});
  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    context.read<WishlistCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Wishlist', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () => context.push('/app/cart'), icon: const Icon(Icons.shopping_bag_outlined)),
        ],
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state.status == WishlistStatus.loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00C805), strokeWidth: 2));
          if (state.items.isEmpty) return EmptyState(icon: Icons.favorite_border_rounded, title: 'Your wishlist is empty', subtitle: 'Save items you love to buy them later', actionLabel: 'Start shopping', onAction: () => context.go('/app/categories'));
          return Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
              Text('${state.count} item${state.count != 1 ? 's' : ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              const Spacer(),
              TextButton(onPressed: () => _addAllToCart(context, state.items), child: const Text('Add all to cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            ])),
            Expanded(child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _WishlistItem(product: state.items[i]),
            )),
          ]);
        },
      ),
    );
  }

  void _addAllToCart(BuildContext context, List<ProductEntity> items) {
    final cubit = context.read<CartCubit>();
    for (final p in items) cubit.add(p);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${items.length} items to cart'), backgroundColor: const Color(0xFF00C805)));
  }
}

class _WishlistItem extends StatelessWidget {
  const _WishlistItem({required this.product});
  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dismissible(
      key: ValueKey('wish_${product.id}'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete_rounded, color: Colors.white)),
      confirmDismiss: (_) async => await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('Remove from wishlist?'), content: Text('Remove "${product.name}"?'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Remove', style: TextStyle(color: Color(0xFFDC2626))))])),
      onDismissed: (_) => context.read<WishlistCubit>().toggle(product),
      child: InkWell(
        onTap: () => context.push('/product/${product.id}', extra: product),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
          child: Row(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)), child: product.images.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(10), child: product.images.first.startsWith('assets/') ? Image.asset(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.spa, color: const Color(0xFF00C805).withOpacity(0.7))) : Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))) : Icon(Icons.spa, color: const Color(0xFF00C805).withOpacity(0.7))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 4),
              Row(children: [Icon(Icons.star_rounded, size: 14, color: const Color(0xFFFFB020)), const SizedBox(width: 2), Text('${product.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
              const SizedBox(height: 4),
              Row(children: [
                Text('₹${product.effectivePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0B0E0F))),
                if (product.onSale) ...[const SizedBox(width: 6), Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough))],
              ]),
              const SizedBox(height: 2),
              if (!product.isInStock) const Text('Out of stock', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
            ])),
            const SizedBox(width: 8),
            Column(children: [
              IconButton(onPressed: () => context.read<WishlistCubit>().toggle(product), icon: const Icon(Icons.favorite_rounded, size: 22, color: Color(0xFFDC2626))),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: product.isInStock ? () {
                    context.read<CartCubit>().add(product);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to cart'), backgroundColor: const Color(0xFF00C805), duration: const Duration(seconds: 1)));
                  } : null,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805), padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
