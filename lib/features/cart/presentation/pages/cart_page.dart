import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../cubit/cart_cubit.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (state.items.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.w800))),
            body: EmptyState(icon: Icons.shopping_bag_outlined, title: 'Your cart is empty', subtitle: 'Add some jaggery goodness to your cart', actionLabel: 'Browse products', onAction: () => context.go('/products')),
          );
        }
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
          appBar: AppBar(title: Text('Cart (${state.count})', style: const TextStyle(fontWeight: FontWeight.w800)), actions: [TextButton(onPressed: () => context.read<CartCubit>().clear(), child: const Text('Clear'))]),
          body: Column(children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final it = state.items[i];
                  return Dismissible(
                    key: ValueKey('${it.product.id}_${it.variantLabel}_$i'),
                    direction: DismissDirection.endToStart,
                    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete_rounded, color: Colors.white)),
                    onDismissed: (_) => context.read<CartCubit>().removeAt(i),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                      child: Row(children: [
                        Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)), child: it.product.images.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(10), child: it.product.images.first.startsWith('assets/') ? Image.asset(it.product.images.first, fit: BoxFit.cover) : Image.network(it.product.images.first, fit: BoxFit.cover)) : const Icon(Icons.spa, color: Color(0xFF00C805))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(it.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          if (it.variantLabel != null) Text(it.variantLabel!, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          const SizedBox(height: 2),
                          Row(children: [Text('₹${it.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF00A63E))), if (it.product.onSale) ...[const SizedBox(width: 6), Text('₹${it.product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: Color(0xFF9CA3AF)))]]),
                        ])),
                        Row(children: [
                          IconButton(onPressed: () => context.read<CartCubit>().setQty(i, it.quantity - 1), icon: const Icon(Icons.remove_circle_outline, size: 20)),
                          Text('${it.quantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          IconButton(onPressed: () => context.read<CartCubit>().setQty(i, it.quantity + 1), icon: const Icon(Icons.add_circle_outline, size: 20)),
                        ]),
                      ]),
                    ),
                  );
                },
              ),
            ),
            _PromoField(),
            _OrderSummary(state: state),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => context.push('/checkout'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))), child: Text('Checkout — ₹${state.total.toStringAsFixed(0)}'))),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _PromoField extends StatefulWidget {
  @override
  State<_PromoField> createState() => _PromoFieldState();
}

class _PromoFieldState extends State<_PromoField> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'Promo code (JAGGERY10, FREESHIP)', suffixIcon: state.promoCode != null ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _ctrl.clear(); context.read<CartCubit>().removePromo(); }) : null))),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => context.read<CartCubit>().applyPromo(_ctrl.text), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805)), child: const Text('Apply')),
          ]),
        );
      },
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.state});
  final CartState state;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
      child: Column(children: [
        _row('Subtotal', '₹${state.subtotal.toStringAsFixed(0)}'),
        _row('Tax (5%)', '₹${state.tax.toStringAsFixed(0)}'),
        _row('Shipping', state.shipping == 0 ? 'Free' : '₹${state.shipping.toStringAsFixed(0)}'),
        if (state.savings > 0) _row('Savings', '-₹${state.savings.toStringAsFixed(0)}', color: const Color(0xFF00A63E)),
        const Divider(height: 16),
        _row('Total', '₹${state.total.toStringAsFixed(0)}', isBold: true),
        if (state.isPromoValid == false) const Padding(padding: EdgeInsets.only(top: 6), child: Align(alignment: Alignment.centerLeft, child: Text('Invalid promo code', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11)))),
        if (state.isPromoValid == true) Padding(padding: const EdgeInsets.only(top: 6), child: Align(alignment: Alignment.centerLeft, child: Text('Promo ${state.promoCode} applied', style: const TextStyle(color: Color(0xFF00A63E), fontSize: 11, fontWeight: FontWeight.w600)))),
      ]),
    );
  }

  Widget _row(String l, String v, {bool isBold = false, Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [Text(l, style: TextStyle(color: const Color(0xFF6B7280), fontSize: 12, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)), const Spacer(), Text(v, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, fontSize: isBold ? 15 : 12, color: color ?? (isBold ? const Color(0xFF0B0E0F) : const Color(0xFF0B0E0F))))]));
}
