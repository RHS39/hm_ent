import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../services/cart_store.dart';
import '../cart/presentation/cubit/cart_cubit.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = ['/app', '/app/search', '/app/cart', '/app/orders', '/app/profile'];
  static const _labels = ['Home', 'Search', 'Cart', 'Orders', 'Profile'];
  static const _icons = [Icons.home_rounded, Icons.search_rounded, Icons.shopping_bag_rounded, Icons.receipt_long_rounded, Icons.person_rounded];

  int _indexFor(String loc) {
    if (loc.startsWith('/app/orders')) return 3;
    if (loc.startsWith('/app/profile')) return 4;
    if (loc.startsWith('/app/cart')) return 2;
    if (loc.startsWith('/app/search') || loc.startsWith('/app/categories')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFor(loc);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final nav = isWide
        ? NavigationRail(
            selectedIndex: idx,
            onDestinationSelected: (i) => context.go(_tabs[i]),
            labelType: NavigationRailLabelType.all,
            leading: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Column(children: [Image.asset('assets/img/logo.png', width: 32, height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.spa, color: Color(0xFF00C805))), const SizedBox(height: 8), const Text('Hari Om', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))])),
            destinations: List.generate(_labels.length, (i) {
              final isCart = i == 2;
              return NavigationRailDestination(
                icon: isCart
                    ? BlocBuilder<CartCubit, CartState>(
                        builder: (_, state) => Badge(label: Text('${state.count}'), isLabelVisible: state.count > 0, child: Icon(_icons[i])),
                      )
                    : Icon(_icons[i]),
                selectedIcon: Icon(_icons[i], color: const Color(0xFF00C805)),
                label: Text(_labels[i]),
              );
            }),
          )
        : null;

    final bottom = isWide
        ? null
        : NavigationBar(
            selectedIndex: idx,
            onDestinationSelected: (i) => context.go(_tabs[i]),
            height: 64,
            destinations: List.generate(_labels.length, (i) {
              final isCart = i == 2;
              return NavigationDestination(
                icon: isCart
                    ? BlocBuilder<CartCubit, CartState>(
                        builder: (_, state) => Badge(
                          label: Text('${state.count}'),
                          isLabelVisible: state.count > 0,
                          backgroundColor: const Color(0xFF00C805),
                          child: const Icon(Icons.shopping_bag_outlined),
                        ),
                      )
                    : Icon(_icons[i]),
                selectedIcon: Icon(_icons[i], color: const Color(0xFF00C805)),
                label: _labels[i],
              );
            }),
          );

    final body = isWide
        ? Row(children: [nav!, const VerticalDivider(width: 1), Expanded(child: child)])
        : child;

    return Scaffold(
      body: body,
      bottomNavigationBar: bottom,
    );
  }
}
