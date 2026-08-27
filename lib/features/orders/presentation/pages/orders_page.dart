import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/empty_state.dart';
import '../cubit/orders_cubit.dart';
import '../../domain/entities/order_entity.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => OrdersCubit(), child: const _OrdersView());
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
          appBar: AppBar(title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w800))),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedButton<OrdersFilter>(
                segments: const [ButtonSegment(value: OrdersFilter.active, label: Text('Active')), ButtonSegment(value: OrdersFilter.completed, label: Text('Completed')), ButtonSegment(value: OrdersFilter.cancelled, label: Text('Cancelled'))],
                selected: {state.filter},
                onSelectionChanged: (s) => context.read<OrdersCubit>().setFilter(s.first),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.filtered.isEmpty
                  ? EmptyState(icon: Icons.receipt_long_rounded, title: 'No ${state.filter.name} orders', subtitle: 'Your orders will appear here')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: state.filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final o = state.filtered[i];
                        return _OrderCard(order: o);
                      },
                    ),
            ),
          ]),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderEntity order;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const steps = [OrderStatus.ordered, OrderStatus.shipped, OrderStatus.outForDelivery, OrderStatus.delivered];
    final currentIdx = steps.indexOf(order.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(order.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: order.status == OrderStatus.cancelled ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100)), child: Text(order.status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: order.status == OrderStatus.cancelled ? const Color(0xFFDC2626) : const Color(0xFF00A63E)))),
        ]),
        const SizedBox(height: 4),
        Text('${order.date.day}/${order.date.month}/${order.date.year} • ₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        const SizedBox(height: 10),
        ...order.items.map((it) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Expanded(child: Text(it.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), Text('×${it.qty}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))), const SizedBox(width: 8), Text('₹${(it.price * it.qty).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]))),
        const SizedBox(height: 10),
        if (order.status != OrderStatus.cancelled)
          Row(children: List.generate(steps.length, (idx) {
            final done = idx <= currentIdx && order.status != OrderStatus.cancelled;
            return Expanded(child: Row(children: [
              Container(width: 20, height: 20, decoration: BoxDecoration(color: done ? const Color(0xFF00C805) : const Color(0xFFE5E7EB), shape: BoxShape.circle), child: done ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null),
              if (idx < steps.length - 1) Expanded(child: Container(height: 2, color: idx < currentIdx ? const Color(0xFF00C805) : const Color(0xFFE5E7EB))),
            ]));
          })),
        const SizedBox(height: 6),
        if (order.status != OrderStatus.cancelled)
          Row(children: ['Ordered', 'Shipped', 'Out for delivery', 'Delivered'].asMap().entries.map((e) => Expanded(child: Text(e.value, style: TextStyle(fontSize: 9, fontWeight: e.key <= currentIdx ? FontWeight.w700 : FontWeight.w500, color: e.key <= currentIdx ? const Color(0xFF00A63E) : const Color(0xFF9CA3AF)), textAlign: TextAlign.center))).toList()),
      ]),
    );
  }
}
