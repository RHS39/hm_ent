import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../appwrite/auth_service.dart';
import '../cart/presentation/cubit/cart_cubit.dart';
import '../orders/presentation/cubit/orders_cubit.dart';
import '../orders/domain/entities/order_entity.dart';
import '../catalog/data/datasources/catalog_remote_datasource.dart';
import '../catalog/domain/entities/product_entity.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  List<ProductEntity> _recommended = [];
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadRecommended();
  }

  Future<void> _loadRecommended() async {
    try {
      final ds = CatalogMockDataSource();
      final products = await ds.getProducts(limit: 6);
      if (mounted) setState(() { _recommended = products; _loadingProducts = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = AppwriteAuthService.displayName;
    final greeting = _greeting();
    final cartCount = context.watch<CartCubit>().state.count;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: () async { await _loadRecommended(); },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(isDark, greeting, userName, cartCount)),
            SliverToBoxAdapter(child: _buildQuickActions(isDark)),
            SliverToBoxAdapter(child: _buildPromoBanner(isDark)),
            SliverToBoxAdapter(child: _buildRecentOrders(isDark)),
            SliverToBoxAdapter(child: _buildRecommendedSection(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildHeader(bool isDark, String greeting, String userName, int cartCount) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0E0F) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$greeting,', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
              const SizedBox(height: 2),
              Text(userName.isNotEmpty ? userName : 'Guest', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0B0E0F), letterSpacing: -0.8)),
            ])),
            Stack(children: [
              IconButton(onPressed: () => context.push('/app/cart'), icon: Icon(Icons.shopping_bag_outlined, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
              if (cartCount > 0) Positioned(right: 4, top: 4, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF00C805), shape: BoxShape.circle), child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
            ]),
            IconButton(onPressed: () => context.go('/app/profile'), icon: Icon(Icons.person_outline_rounded, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
          ]),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      _QuickAction(Icons.receipt_long_rounded, 'My Orders', '/app/orders', const Color(0xFF2563EB)),
      _QuickAction(Icons.local_shipping_rounded, 'Track Order', '/app/orders', const Color(0xFFEA580C)),
      _QuickAction(Icons.favorite_rounded, 'Wishlist', '/app/wishlist', const Color(0xFFDC2626)),
      _QuickAction(Icons.location_on_rounded, 'Addresses', '/app/profile', const Color(0xFF7C3AED)),
      _QuickAction(Icons.settings_rounded, 'Settings', '/app/profile', const Color(0xFF6B7280)),
      _QuickAction(Icons.headset_mic_rounded, 'Support', '/contact', const Color(0xFF059669)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.1, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemBuilder: (context, i) {
              final a = actions[i];
              return _QuickActionCard(action: a, isDark: isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isDark ? [const Color(0xFF1A2E1A), const Color(0xFF0D3320)] : [const Color(0xFF00C805), const Color(0xFF00A63E)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF00C805).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)), child: const Text('LIMITED OFFER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
            const SizedBox(height: 8),
            const Text('Free shipping on orders over ₹499', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Use code FREESHIP at checkout', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ])),
          const SizedBox(width: 12),
          Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28)),
        ]),
      ),
    );
  }

  Widget _buildRecentOrders(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
            const Spacer(),
            TextButton(onPressed: () => context.go('/app/orders'), child: const Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 4),
          BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, state) {
              final recent = state.orders.take(2).toList();
              if (recent.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                  child: Center(child: Text('No orders yet', style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF6B7280), fontSize: 13))),
                );
              }
              return Column(children: recent.map((o) => _OrderCompactCard(order: o, isDark: isDark)).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Row(children: [
            Text('Recommended for You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
            const Spacer(),
            TextButton(onPressed: () => context.go('/app/categories'), child: const Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
        ),
        if (_loadingProducts)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: Color(0xFF00C805), strokeWidth: 2)))
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _recommended.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _RecommendedCard(product: _recommended[i], isDark: isDark),
            ),
          ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.route, this.color);
  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.isDark});
  final _QuickAction action;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(action.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: action.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(action.icon, size: 20, color: action.color)),
          const SizedBox(height: 8),
          Text(action.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF374151)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _OrderCompactCard extends StatelessWidget {
  const _OrderCompactCard({required this.order, required this.isDark});
  final OrderEntity order;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const statusColors = {
      OrderStatus.ordered: Color(0xFF2563EB),
      OrderStatus.shipped: Color(0xFFEA580C),
      OrderStatus.outForDelivery: Color(0xFF7C3AED),
      OrderStatus.delivered: Color(0xFF059669),
      OrderStatus.cancelled: Color(0xFFDC2626),
    };
    final color = statusColors[order.status] ?? const Color(0xFF6B7280);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(_statusIcon(order.status), size: 20, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text('${order.items.length} item${order.items.length > 1 ? 's' : ''} • ₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(100)), child: Text(order.status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.ordered: return Icons.shopping_bag_rounded;
      case OrderStatus.shipped: return Icons.local_shipping_rounded;
      case OrderStatus.outForDelivery: return Icons.delivery_dining_rounded;
      case OrderStatus.delivered: return Icons.check_circle_rounded;
      case OrderStatus.cancelled: return Icons.cancel_rounded;
    }
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.product, required this.isDark});
  final ProductEntity product;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/product/${product.id}', extra: product),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 150,
        decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Stack(children: [
            Container(width: double.infinity, color: product.isInStock ? const Color(0xFFFFF7ED) : const Color(0xFFF3F4F6), child: product.images.isNotEmpty ? (product.images.first.startsWith('assets/') ? Image.asset(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.spa, size: 32, color: const Color(0xFF00C805).withOpacity(0.7))) : Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 32))) : const Icon(Icons.spa, size: 32)),
            if (product.onSale) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(100)), child: Text('-${product.discountPercent.round()}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
