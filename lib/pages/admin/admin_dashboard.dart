import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../appwrite/auth_service.dart';
import '../../appwrite/appwrite_client.dart';
import '../../appwrite/contact_repository.dart';
import '../../appwrite/subscriber_repository.dart';
import '../../appwrite/product_repository.dart';
import '../../appwrite/user_repository.dart';
import '../../services/product_store.dart';
import 'admin_widgets.dart';
import 'admin_overview_section.dart';
import 'admin_contacts_section.dart';
import 'admin_products_section.dart';
import 'admin_subscribers_section.dart';
import 'admin_users_section.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _section = 0;

  int _totalSubscribers = 0;
  int _activeSubscribers = 0;
  int _totalContacts = 0;
  int _newContacts = 0;
  bool _loading = true;

  List<Map<String, dynamic>> _recentSubscribers = [];
  List<Map<String, dynamic>> _recentContacts = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _users = [];

  late final VoidCallback _storeListener;

  int _sectionFromRoute(BuildContext context) {
    final path = GoRouterState.of(context).matchedLocation;
    if (path.startsWith('/admin/users')) return 4;
    if (path.startsWith('/admin/subscribers')) return 3;
    if (path.startsWith('/admin/products')) return 2;
    if (path.startsWith('/admin/contacts')) return 1;
    return 0;
  }

  String _routeForSection(int section) {
    switch (section) {
      case 1: return '/admin/contacts';
      case 2: return '/admin/products';
      case 3: return '/admin/subscribers';
      case 4: return '/admin/users';
      default: return '/admin';
    }
  }

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Initial sync to avoid empty flash if store already has data
    if (ProductStore.instance.products.isNotEmpty) {
      _products = List<Map<String, dynamic>>.from(ProductStore.instance.products);
    }
    _storeListener = () {
      if (!mounted) return;
      final fresh = ProductStore.instance.products;
      // Guard: never overwrite with empty while we have data (prevents flash/blank after update)
      if (fresh.isEmpty && _products.isNotEmpty) return;
      // Only rebuild if reference or length changed to avoid unnecessary builds
      if (!identical(fresh, _products) || fresh.length != _products.length) {
        setState(() => _products = List<Map<String, dynamic>>.from(fresh));
      } else {
        // Even if same length, data inside may have mutated (demo fallback mutates in-place)
        setState(() => _products = List<Map<String, dynamic>>.from(fresh));
      }
    };
    ProductStore.instance.addListener(_storeListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeSection = _sectionFromRoute(context);
    if (!_initialized || routeSection != _section) {
      _initialized = true;
      _section = routeSection;
      _loadData();
    }
  }

  @override
  void dispose() {
    ProductStore.instance.removeListener(_storeListener);
    super.dispose();
  }

  Future<void> _syncProducts() async {
    try {
      final freshProducts = await AppwriteProductRepository.fetchProducts();
      if (freshProducts.isEmpty && !AppwriteService.isInitialized) {
        ProductStore.instance.ensureDemoSeed();
        final fallback = ProductStore.instance.products;
        if (fallback.isNotEmpty) {
          if (!mounted) return;
          setState(() => _products = fallback);
          return;
        }
      }
      ProductStore.instance.replaceAll(freshProducts);
      if (!mounted) return;
      setState(() => _products = freshProducts);
    } catch (e) {
      debugPrint('[Admin] _syncProducts failed: $e');
      if (!AppwriteService.isInitialized) {
        ProductStore.instance.ensureDemoSeed();
        if (mounted) setState(() => _products = ProductStore.instance.products);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final usersFuture = AppwriteService.isInitialized
          ? AppwriteUserRepository.fetchAll(limit: 50)
          : Future.value(<Map<String, dynamic>>[]);
      final results = await Future.wait([
        AppwriteSubscriberRepository.fetchRecent(limit: 50),
        AppwriteSubscriberRepository.countByStatus(),
        AppwriteContactRepository.fetchRecent(limit: 50),
        AppwriteProductRepository.fetchProducts(),
        usersFuture,
      ]);
      if (!mounted) return;
      var freshProducts = results[3] as List<Map<String, dynamic>>;
      if (freshProducts.isEmpty && !AppwriteService.isInitialized) {
        ProductStore.instance.ensureDemoSeed();
        freshProducts = ProductStore.instance.products;
      }
      if (freshProducts.isNotEmpty) ProductStore.instance.replaceAll(freshProducts);
      var freshUsers = results[4] as List<Map<String, dynamic>>;
      if (freshUsers.isEmpty) {
        freshUsers = _demoUsers();
        if (AppwriteService.isInitialized) {
          for (final u in freshUsers) {
            try {
              await AppwriteUserRepository.create(
                userId: (u['id'] ?? u[r'$id'] ?? '').toString(),
                name: (u['name'] ?? '').toString(),
                email: (u['email'] ?? '').toString(),
                phone: (u['phone'] ?? '').toString(),
                role: (u['role'] ?? 'customer').toString(),
                privileges: List<String>.from(u['privileges'] is List ? u['privileges'] as List : AppwriteUserRepository.parsePrivileges(u['privileges'])),
                status: (u['status'] ?? 'active').toString(),
                emailVerification: u['emailVerification'] == true,
                phoneVerification: u['phoneVerification'] == true,
              );
            } catch (_) {}
          }
          try {
            final reseeded = await AppwriteUserRepository.fetchAll(limit: 50);
            if (reseeded.isNotEmpty) freshUsers = reseeded;
          } catch (_) {}
        }
      }
      setState(() {
        _recentSubscribers = results[0] as List<Map<String, dynamic>>;
        final counts = results[1] as Map<String, int>;
        _totalSubscribers = counts.values.fold(0, (a, b) => a + b);
        _activeSubscribers = counts['active'] ?? 0;
        _recentContacts = results[2] as List<Map<String, dynamic>>;
        _totalContacts = _recentContacts.length;
        _newContacts = _recentContacts.where((m) => m['status'] == 'new').length;
        _products = freshProducts;
        _users = freshUsers;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[Admin] _loadData failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectSection(int i) {
    context.go(_routeForSection(i));
  }

  List<Map<String, dynamic>> _demoUsers() {
    final now = DateTime.now();
    String iso(int daysAgo) => now.subtract(Duration(days: daysAgo)).toIso8601String();
    final current = AppwriteAuthService.currentUser;
    final demo = <Map<String, dynamic>>[
      {'id': 'u1', '\$id': 'u1', 'name': 'Rohit Sharma', 'email': 'rohit@hariomtraders.com', 'phone': '9665274622', 'role': 'admin', 'status': 'active', 'emailVerification': true, 'phoneVerification': true, '\$createdAt': iso(2), 'labels': ['admin'], 'privileges': '["manage_products","manage_users","manage_contacts","view_analytics"]'},
      {'id': 'u2', '\$id': 'u2', 'name': 'Aman Singh', 'email': 'aman.singh@example.com', 'phone': '9876543210', 'role': 'customer', 'status': 'active', 'emailVerification': true, 'phoneVerification': false, '\$createdAt': iso(5), 'labels': [], 'privileges': '["view_products","place_orders","view_orders","manage_cart"]'},
      {'id': 'u3', '\$id': 'u3', 'name': 'Priya Verma', 'email': 'priya.verma@example.com', 'phone': '9123456780', 'role': 'customer', 'status': 'pending', 'emailVerification': false, 'phoneVerification': false, '\$createdAt': iso(8), 'labels': [], 'privileges': '["view_products"]'},
      {'id': 'u4', '\$id': 'u4', 'name': 'Test User', 'email': 'test@example.com', 'phone': '9000000001', 'role': 'customer', 'status': 'active', 'emailVerification': true, 'phoneVerification': true, '\$createdAt': iso(12), 'labels': [], 'privileges': '["view_products","place_orders","manage_wishlist"]'},
      {'id': 'u5', '\$id': 'u5', 'name': 'Neha Gupta', 'email': 'neha.gupta@example.com', 'phone': '9988776655', 'role': 'customer', 'status': 'blocked', 'emailVerification': true, 'phoneVerification': true, '\$createdAt': iso(15), 'labels': [], 'privileges': '[]'},
      {'id': 'u6', '\$id': 'u6', 'name': 'Vikash Yadav', 'email': 'vikash.yadav@example.com', 'phone': '9090909090', 'role': 'admin', 'status': 'active', 'emailVerification': true, 'phoneVerification': true, '\$createdAt': iso(20), 'labels': ['admin'], 'privileges': '["manage_products","manage_orders","view_analytics","manage_inventory"]'},
      {'id': 'u7', '\$id': 'u7', 'name': 'Anjali Mehta', 'email': 'anjali@example.com', 'phone': '8887776665', 'role': 'customer', 'status': 'active', 'emailVerification': false, 'phoneVerification': true, '\$createdAt': iso(30), 'labels': [], 'privileges': '["view_products","view_orders","contact_support"]'},
      {'id': 'u8', '\$id': 'u8', 'name': 'Demo Buyer', 'email': 'buyer@demo.com', 'phone': '7776665554', 'role': 'customer', 'status': 'active', 'emailVerification': true, 'phoneVerification': false, '\$createdAt': iso(1), 'labels': [], 'privileges': '["view_products","place_orders","manage_cart","view_invoices"]'},
    ];
    if (current != null) {
      final exists = demo.any((u) => (u['email'] as String).toLowerCase() == current.email.toLowerCase());
      if (!exists) {
        demo.insert(0, {
          'id': current.$id,
          '\$id': current.$id,
          'name': current.name.isEmpty ? current.email.split('@').first : current.name,
          'email': current.email,
          'phone': current.phone,
          'role': AppwriteAuthService.isAdmin ? 'admin' : 'customer',
          'status': 'active',
          'emailVerification': current.emailVerification,
          'phoneVerification': current.phoneVerification,
          '\$createdAt': current.$createdAt,
          'labels': current.labels,
        });
      }
    }
    return demo;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 800;
    final name = AppwriteAuthService.displayName;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          if (!isMobile) Sidebar(section: _section, onSelect: _selectSection),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      if (isMobile)
                        IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () => _showMobileNav(context),
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          ['Dashboard Overview', 'Contact Messages', 'Products', 'Subscriber Directory', 'Users'][_section.clamp(0, 4)],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F)),
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        fit: FlexFit.tight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFF00C805),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0B0E0F))),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        tooltip: 'Log out',
                        onPressed: () async {
                          await AppwriteAuthService.signOut();
                          if (context.mounted) context.go('/');
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C805)))
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (_section == 2) {
                              await _syncProducts();
                            } else {
                              await _loadData();
                            }
                          },
                          child: ListView(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            children: [
                              if (_section == 0)
                                OverviewSection(
                                  totalSubscribers: _totalSubscribers,
                                  activeSubscribers: _activeSubscribers,
                                  totalContacts: _totalContacts,
                                  newContacts: _newContacts,
                                  isMobile: isMobile,
                                  onExportSubscribers: () {},
                                  onExportContacts: () {},
                                  recentSubscribers: _recentSubscribers,
                                  recentContacts: _recentContacts,
                                  onContactTap: (_) {},
                                ),
                              if (_section == 1)
                                ContactsSection(
                                  contacts: _recentContacts,
                                  isMobile: isMobile,
                                ),
                              if (_section == 2)
                                ProductsSection(
                                  products: _products,
                                  isMobile: isMobile,
                                ),
                              if (_section == 3)
                                SubscribersSection(
                                  subscribers: _recentSubscribers,
                                  isMobile: isMobile,
                                  onRefresh: _loadData,
                                ),
                              if (_section == 4)
                                UsersSection(
                                  users: _users,
                                  isMobile: isMobile,
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileNav(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.dashboard_rounded), title: const Text('Overview', overflow: TextOverflow.ellipsis), selected: _section == 0, onTap: () { Navigator.pop(ctx); _selectSection(0); }),
            ListTile(leading: const Icon(Icons.mail_rounded), title: const Text('Contact Messages', overflow: TextOverflow.ellipsis), selected: _section == 1, onTap: () { Navigator.pop(ctx); _selectSection(1); }),
            ListTile(leading: const Icon(Icons.inventory_2_rounded), title: const Text('Products', overflow: TextOverflow.ellipsis), selected: _section == 2, onTap: () { Navigator.pop(ctx); _selectSection(2); }),
            ListTile(leading: const Icon(Icons.how_to_reg_rounded), title: const Text('Subscribers', overflow: TextOverflow.ellipsis), selected: _section == 3, onTap: () { Navigator.pop(ctx); _selectSection(3); }),
            ListTile(leading: const Icon(Icons.group_rounded), title: const Text('Users', overflow: TextOverflow.ellipsis), selected: _section == 4, onTap: () { Navigator.pop(ctx); _selectSection(4); }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Back to Site'),
              onTap: () { Navigator.pop(ctx); context.go('/'); },
            ),
          ],
        ),
      ),
    );
  }
}
