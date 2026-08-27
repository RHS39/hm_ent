import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/cart_cubit.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _step = 0;
  String? _selectedAddress;
  String _payment = 'COD';
  bool _placing = false;

  final _addresses = [
    {'id': '1', 'label': 'Home', 'address': '123, Assi Ghat, Varanasi, UP 221005', 'phone': '9876543210'},
    {'id': '2', 'label': 'Office', 'address': '45, Sigra, Varanasi, UP 221010', 'phone': '9123456789'},
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _stepCard(
              index: 0,
              title: 'Shipping Address',
              isExpanded: _step == 0,
              isCompleted: _selectedAddress != null,
              onTap: () => setState(() => _step = 0),
              child: Column(children: [
                ..._addresses.map((a) => RadioListTile<String>(value: a['id']!, groupValue: _selectedAddress, onChanged: (v) => setState(() => _selectedAddress = v), title: Text('${a['label']}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${a['address']}\n${a['phone']}'), activeColor: const Color(0xFF00C805))),
                OutlinedButton.icon(onPressed: () => _addAddress(), icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Add new address')),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _selectedAddress == null ? null : () => setState(() => _step = 1), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F)), child: const Text('Continue'))),
              ]),
            ),
            const SizedBox(height: 12),
            _stepCard(
              index: 1,
              title: 'Payment Method',
              isExpanded: _step == 1,
              isCompleted: _step > 1,
              onTap: () => setState(() => _step = 1),
              child: Column(children: [
                RadioListTile<String>(value: 'COD', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: const Text('Cash on Delivery'), secondary: const Icon(Icons.payments_rounded), activeColor: const Color(0xFF00C805)),
                RadioListTile<String>(value: 'UPI', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: const Text('UPI'), subtitle: const Text('GPay, PhonePe, Paytm'), secondary: const Icon(Icons.qr_code_rounded), activeColor: const Color(0xFF00C805)),
                RadioListTile<String>(value: 'CARD', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: const Text('Card'), subtitle: const Text('Credit/Debit'), secondary: const Icon(Icons.credit_card_rounded), activeColor: const Color(0xFF00C805)),
                if (_payment == 'CARD') Padding(padding: const EdgeInsets.only(top: 8), child: TextField(decoration: InputDecoration(hintText: 'Card number', prefixIcon: const Icon(Icons.credit_card_rounded)), keyboardType: TextInputType.number)),
                const SizedBox(height: 8),
                Row(children: [Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 0), child: const Text('Back'))), const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: () => setState(() => _step = 2), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F)), child: const Text('Continue')))]),
              ]),
            ),
            const SizedBox(height: 12),
            _stepCard(
              index: 2,
              title: 'Order Review',
              isExpanded: _step == 2,
              isCompleted: false,
              onTap: () => setState(() => _step = 2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ...cart.items.map((it) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
                      Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)), child: it.product.images.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(8), child: it.product.images.first.startsWith('assets/') ? Image.asset(it.product.images.first, fit: BoxFit.cover) : Image.network(it.product.images.first, fit: BoxFit.cover)) : const Icon(Icons.spa)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(it.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), Text('Qty ${it.quantity} • ₹${it.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))])),
                      Text('₹${it.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]))),
                const Divider(height: 16),
                _summaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
                _summaryRow('Tax', '₹${cart.tax.toStringAsFixed(0)}'),
                _summaryRow('Shipping', cart.shipping == 0 ? 'Free' : '₹${cart.shipping.toStringAsFixed(0)}'),
                _summaryRow('Discount', '-₹${cart.discount.toStringAsFixed(0)}', color: const Color(0xFF00A63E)),
                const Divider(height: 16),
                _summaryRow('Total', '₹${cart.total.toStringAsFixed(0)}', isBold: true),
              ]),
            ),
          ],
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, border: Border(top: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)))),
            child: SizedBox(width: double.infinity, child: FilledButton(onPressed: _placing || _selectedAddress == null ? null : _placeOrder, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805), padding: const EdgeInsets.symmetric(vertical: 14)), child: _placing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Place Order — ₹${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)))),
          ),
        ),
        if (_placing) Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator(color: Color(0xFF00C805)))),
      ]),
    );
  }

  Widget _stepCard({required int index, required String title, required bool isExpanded, required bool isCompleted, required VoidCallback onTap, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
      child: Column(children: [
        InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child: Row(children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: isCompleted ? const Color(0xFF00C805) : (isExpanded ? const Color(0xFF0B0E0F) : const Color(0xFFE5E7EB)), shape: BoxShape.circle), child: Center(child: isCompleted ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : Text('${index + 1}', style: TextStyle(color: isExpanded ? Colors.white : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const Spacer(),
              Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: const Color(0xFF6B7280)),
            ]))),
        if (isExpanded) ...[const Divider(height: 1), Padding(padding: const EdgeInsets.all(14), child: child)],
      ]),
    );
  }

  Widget _summaryRow(String l, String v, {bool isBold = false, Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Text(l, style: TextStyle(fontSize: 12, color: const Color(0xFF6B7280), fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)), const Spacer(), Text(v, style: TextStyle(fontSize: isBold ? 15 : 12, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: color ?? const Color(0xFF0B0E0F)))]));
  void _addAddress() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 12), const TextField(decoration: InputDecoration(labelText: 'Full address')), const SizedBox(height: 8), const TextField(decoration: InputDecoration(labelText: 'Pincode')), const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F)), child: const Text('Save')))]))));
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final id = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    setState(() => _placing = false);
    context.read<CartCubit>().clear();
    context.go('/order-success/$id');
  }
}
