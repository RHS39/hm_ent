import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'appwrite/appwrite_client.dart';
import 'appwrite/auth_service.dart';
import 'widgets/app_header.dart';
import 'pages/home_page.dart';
import 'pages/products_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/contact_us_page.dart';
import 'pages/about_us_page.dart';
import 'pages/feature_detail_page.dart';
import 'pages/dynamic_content_page.dart';
import 'pages/verify_email_page.dart';
import 'pages/auth/auth_page.dart';
import 'pages/admin/admin_dashboard.dart';

// New post-login features
import 'core/theme/app_theme.dart';
import 'features/catalog/presentation/pages/catalog_page.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/cart/presentation/pages/checkout_page.dart';
import 'features/cart/presentation/pages/order_success_page.dart';
import 'features/orders/presentation/pages/orders_page.dart';
import 'features/orders/presentation/cubit/orders_cubit.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/app_shell/app_shell.dart';
import 'features/app_shell/customer_dashboard.dart';
import 'features/search/presentation/pages/search_page.dart';
import 'features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'features/wishlist/presentation/pages/wishlist_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwriteService.init();
  try {
    await AppwriteAuthService.initListener();
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: appwriteUserNotifier,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final isAdminRoute = loc.startsWith('/admin');
        final isAuthRoute = loc == '/login' || loc == '/signup';
        final isProtected = loc.startsWith('/app') || loc == '/cart' || loc == '/checkout' || loc.startsWith('/order-success');
        final loggedIn = AppwriteAuthService.isLoggedIn;
        final isAdmin = AppwriteAuthService.isAdmin;

        if (isAdminRoute && !loggedIn) return '/login';
        if (isAdminRoute && loggedIn && !isAdmin) return '/';
        if (isProtected && !loggedIn) return '/login';
        if (isAuthRoute && loggedIn) {
          return isAdmin ? '/admin' : '/app';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', name: 'home', builder: (context, state) => const HomePage()),
        GoRoute(path: '/products', name: 'products', builder: (context, state) => const ProductsPage()),
        GoRoute(
          path: '/product/:id',
          name: 'product-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final extra = state.extra;
            Product? initial;
            if (extra is Product) initial = extra;
            return ProductDetailPage(productId: id, initialProduct: initial);
          },
        ),
        GoRoute(path: '/contact', name: 'contact', builder: (context, state) => const ContactUsPage()),
        GoRoute(path: '/contact-us', redirect: (context, state) => '/contact'),
        GoRoute(path: '/about', name: 'about', builder: (context, state) => const AboutUsPage()),
        GoRoute(path: '/feature/:slug', name: 'feature', builder: (context, state) => FeatureDetailPage(slug: state.pathParameters['slug'] ?? 'unknown')),
        GoRoute(path: '/content/:slug', name: 'content', builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? 'unknown';
          final q = state.uri.queryParameters;
          return DynamicContentPage(slug: slug, title: q['title'], body: q['body']);
        }),
        GoRoute(path: '/verify-email', name: 'verify-email', builder: (context, state) => VerifyEmailPage(token: state.uri.queryParameters['token'])),
        GoRoute(path: '/login', name: 'login', builder: (context, state) => const AuthPage(initialMode: AuthMode.login)),
        GoRoute(path: '/signup', name: 'signup', builder: (context, state) => const AuthPage(initialMode: AuthMode.signup)),
        // Cart standalone (redirect alias)
        GoRoute(path: '/cart', redirect: (context, state) => '/app/cart'),
        GoRoute(path: '/checkout', builder: (context, state) => const CheckoutPage()),
        GoRoute(path: '/order-success/:id', builder: (context, state) => OrderSuccessPage(orderId: state.pathParameters['id'] ?? '000')),
        // Admin
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) => const AdminDashboard(),
          routes: [
            GoRoute(path: 'products', builder: (context, state) => const AdminDashboard()),
            GoRoute(path: 'users', builder: (context, state) => const AdminDashboard()),
            GoRoute(path: 'subscribers', builder: (context, state) => const AdminDashboard()),
            GoRoute(path: 'contacts', builder: (context, state) => const AdminDashboard()),
          ],
        ),
        // POST-LOGIN SHELL: adaptive bottom nav + nav rail
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/app', builder: (context, state) => const CustomerDashboard()),
            GoRoute(path: '/app/search', builder: (context, state) => const SearchPage()),
            GoRoute(path: '/app/categories', builder: (context, state) => const CatalogPage()),
            GoRoute(path: '/app/cart', builder: (context, state) => const CartPage()),
            GoRoute(path: '/app/orders', builder: (context, state) => const OrdersPage()),
            GoRoute(path: '/app/wishlist', builder: (context, state) => const WishlistPage()),
            GoRoute(path: '/app/profile', builder: (context, state) => const ProfilePage()),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFF6B7280)),
              const SizedBox(height: 12),
              Text('No route for ${state.matchedLocation}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(state.error?.toString() ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => context.go('/'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F)), child: const Text('Go Home')),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>(create: (_) => CartCubit()),
        BlocProvider<OrdersCubit>(create: (_) => OrdersCubit()),
        BlocProvider<WishlistCubit>(create: (_) => WishlistCubit()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController,
        builder: (context, mode, _) {
          return MaterialApp.router(
            title: 'Hari Om Traders — Organic Jaggery',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
