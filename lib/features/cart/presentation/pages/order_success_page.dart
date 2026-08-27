import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key, required this.orderId});
  final String orderId;
  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delivery = DateTime.now().add(const Duration(days: 3));
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(scale: _scale, child: Container(width: 96, height: 96, decoration: const BoxDecoration(color: Color(0xFF00C805), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 56, color: Colors.white))),
            const SizedBox(height: 16),
            Text('Order Placed!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : Colors.white, borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))), child: Text('Order #${widget.orderId}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            const SizedBox(height: 12),
            Text('Estimated delivery by ${delivery.day}/${delivery.month}/${delivery.year}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => context.go('/app/orders'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Track Order'))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.go('/app'), child: const Text('Continue Shopping'))),
          ]),
        ),
      ),
    );
  }
}
