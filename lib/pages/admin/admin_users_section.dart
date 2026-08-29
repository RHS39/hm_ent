import 'dart:async';
import 'package:flutter/material.dart';
import 'admin_widgets.dart';
import '../../appwrite/user_repository.dart';
import '../../appwrite/appwrite_client.dart';
import '../../appwrite/auth_service.dart';

class UsersSection extends StatefulWidget {
  const UsersSection({
    required this.users,
    required this.isMobile,
    this.onUserTap,
  });

  final List<Map<String, dynamic>> users;
  final bool isMobile;
  final ValueChanged<Map<String, dynamic>>? onUserTap;

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  List<Map<String, dynamic>> _localUsers = [];
  String _userSearch = '';
  String _userRoleFilter = 'all';
  String _userStatusFilter = 'all';

  static List<Map<String, dynamic>> _demoUsers() {
    final now = DateTime.now();
    String iso(int daysAgo) =>
        now.subtract(Duration(days: daysAgo)).toIso8601String();
    final current = AppwriteAuthService.currentUser;
    final demo = <Map<String, dynamic>>[
      {
        'id': 'u1',
        r'$id': 'u1',
        'name': 'Rohit Sharma',
        'email': 'rohit@hariomtraders.com',
        'phone': '9665274622',
        'role': 'admin',
        'status': 'active',
        'emailVerification': true,
        'phoneVerification': true,
        r'$createdAt': iso(2),
        'labels': ['admin'],
        'privileges':
            '["manage_products","manage_users","manage_contacts","view_analytics"]'
      },
      {
        'id': 'u2',
        r'$id': 'u2',
        'name': 'Aman Singh',
        'email': 'aman.singh@example.com',
        'phone': '9876543210',
        'role': 'customer',
        'status': 'active',
        'emailVerification': true,
        'phoneVerification': false,
        r'$createdAt': iso(5),
        'labels': [],
        'privileges':
            '["view_products","place_orders","view_orders","manage_cart"]'
      },
      {
        'id': 'u3',
        r'$id': 'u3',
        'name': 'Priya Verma',
        'email': 'priya.verma@example.com',
        'phone': '9123456780',
        'role': 'customer',
        'status': 'pending',
        'emailVerification': false,
        'phoneVerification': false,
        r'$createdAt': iso(8),
        'labels': [],
        'privileges': '["view_products"]'
      },
      {
        'id': 'u4',
        r'$id': 'u4',
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '9000000001',
        'role': 'customer',
        'status': 'active',
        'emailVerification': true,
        'phoneVerification': true,
        r'$createdAt': iso(12),
        'labels': [],
        'privileges':
            '["view_products","place_orders","manage_wishlist"]'
      },
      {
        'id': 'u5',
        r'$id': 'u5',
        'name': 'Neha Gupta',
        'email': 'neha.gupta@example.com',
        'phone': '9988776655',
        'role': 'customer',
        'status': 'blocked',
        'emailVerification': true,
        'phoneVerification': true,
        r'$createdAt': iso(15),
        'labels': [],
        'privileges': '[]'
      },
      {
        'id': 'u6',
        r'$id': 'u6',
        'name': 'Vikash Yadav',
        'email': 'vikash.yadav@example.com',
        'phone': '9090909090',
        'role': 'admin',
        'status': 'active',
        'emailVerification': true,
        'phoneVerification': true,
        r'$createdAt': iso(20),
        'labels': ['admin'],
        'privileges':
            '["manage_products","manage_orders","view_analytics","manage_inventory"]'
      },
      {
        'id': 'u7',
        r'$id': 'u7',
        'name': 'Anjali Mehta',
        'email': 'anjali@example.com',
        'phone': '8887776665',
        'role': 'customer',
        'status': 'active',
        'emailVerification': false,
        'phoneVerification': true,
        r'$createdAt': iso(30),
        'labels': [],
        'privileges':
            '["view_products","view_orders","contact_support"]'
      },
      {
        'id': 'u8',
        r'$id': 'u8',
        'name': 'Demo Buyer',
        'email': 'buyer@demo.com',
        'phone': '7776665554',
        'role': 'customer',
        'status': 'active',
        'emailVerification': true,
        'phoneVerification': false,
        r'$createdAt': iso(1),
        'labels': [],
        'privileges':
            '["view_products","place_orders","manage_cart","view_invoices"]'
      },
    ];
    if (current != null) {
      final exists = demo.any((u) =>
          (u['email'] as String).toLowerCase() ==
          current.email.toLowerCase());
      if (!exists) {
        demo.insert(0, {
          'id': current.$id,
          r'$id': current.$id,
          'name':
              current.name.isEmpty ? current.email.split('@').first : current.name,
          'email': current.email,
          'phone': current.phone,
          'role': AppwriteAuthService.isAdmin ? 'admin' : 'customer',
          'status': 'active',
          'emailVerification': current.emailVerification,
          'phoneVerification': current.phoneVerification,
          r'$createdAt': current.$createdAt,
          'labels': current.labels,
        });
      }
    }
    return demo;
  }

  @override
  void initState() {
    super.initState();
    _localUsers = widget.users.isEmpty
        ? List<Map<String, dynamic>>.from(_demoUsers())
        : List<Map<String, dynamic>>.from(widget.users);
  }

  @override
  void didUpdateWidget(covariant UsersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.users != oldWidget.users) {
      _localUsers = widget.users.isEmpty
          ? List<Map<String, dynamic>>.from(_demoUsers())
          : List<Map<String, dynamic>>.from(widget.users);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var list = List<Map<String, dynamic>>.from(
        _localUsers.isEmpty ? _demoUsers() : _localUsers);
    if (_userSearch.isNotEmpty) {
      final q = _userSearch.toLowerCase();
      list = list
          .where((u) =>
              (u['name'] ?? '').toString().toLowerCase().contains(q) ||
              (u['email'] ?? '').toString().toLowerCase().contains(q) ||
              (u['phone'] ?? '').toString().contains(q))
          .toList();
    }
    if (_userRoleFilter != 'all') {
      list = list
          .where((u) => (u['role'] ?? '').toString() == _userRoleFilter)
          .toList();
    }
    if (_userStatusFilter != 'all') {
      list = list
          .where((u) => (u['status'] ?? '').toString() == _userStatusFilter)
          .toList();
    }
    list.sort((a, b) => (b[r'$createdAt'] ?? '')
        .toString()
        .compareTo((a[r'$createdAt'] ?? '').toString()));
    return list;
  }

  List<Map<String, dynamic>> get _sourceUsers =>
      _localUsers.isEmpty ? _demoUsers() : _localUsers;

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString());
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return raw.toString().substring(0, 10);
    }
  }

  void _showUserDialog(Map<String, dynamic> u) {
    final docId = (u['id'] ?? u[r'$id'] ?? '').toString();
    final name = (u['name'] ?? '').toString();
    final email = (u['email'] ?? '').toString();
    final phone = (u['phone'] ?? '').toString();
    final initialRole = (u['role'] ?? 'customer').toString();
    final initialStatus = (u['status'] ?? 'active').toString();
    final initialPrivs = AppwriteUserRepository.privilegesOf(u);
    final raw =
        u[r'$createdAt'] ?? u['created_at'] ?? u[r'$created_at'] ?? '';
    DateTime? dt;
    try {
      dt = DateTime.parse(raw.toString()).toLocal();
    } catch (_) {}
    final joined = dt != null
        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';
    final timeAgo = dt != null ? _formatDate(dt.toIso8601String()) : '';
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    String selectedRole = initialRole;
    String selectedStatus = initialStatus;
    List<String> selectedPrivs = List<String>.from(initialPrivs);
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isAdmin = selectedRole == 'admin';
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 4,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: isAdmin
                                    ? [
                                        const Color(0xFF7C3AED),
                                        const Color(0xFF4F46E5)
                                      ]
                                    : [
                                        const Color(0xFF00C805),
                                        const Color(0xFF059669)
                                      ]),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)))),
                    const SizedBox(height: 12),
                    Row(children: [
                      Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: isAdmin
                                      ? [
                                          const Color(0xFF7C3AED),
                                          const Color(0xFF4F46E5)
                                        ]
                                      : [
                                          const Color(0xFF00C805),
                                          const Color(0xFF10B981)
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(16)),
                          child: Center(
                              child: Text(initial,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20)))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0B0E0F))),
                            Text(email,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600)),
                            Text(phone,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7280))),
                          ])),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB))),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 14, color: Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Text('$joined  $timeAgo',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B0E0F))),
                        ])),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: DropdownButtonFormField<String>(
                              value: selectedRole,
                              decoration: const InputDecoration(
                                  labelText: 'Role',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10)))),
                              items: AppwriteUserRepository.allRoles
                                  .map((r) => DropdownMenuItem(
                                      value: r, child: Text(r)))
                                  .toList(),
                              onChanged: (v) => setDialogState(() {
                                    selectedRole = v ?? 'user';
                                    selectedPrivs = selectedPrivs
                                        .where((p) =>
                                            AppwriteUserRepository
                                                .privilegesForRole(
                                                    selectedRole)
                                                .contains(p))
                                        .toList();
                                  }))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: DropdownButtonFormField<String>(
                              value: selectedStatus,
                              decoration: const InputDecoration(
                                  labelText: 'Status',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10)))),
                              items: AppwriteUserRepository.allStatuses
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setDialogState(
                                  () => selectedStatus = v ?? 'active'))),
                    ]),
                    const SizedBox(height: 12),
                    const Text('Privileges',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151))),
                    const SizedBox(height: 6),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppwriteUserRepository
                            .privilegesForRole(selectedRole)
                            .map((p) {
                          final sel = selectedPrivs.contains(p);
                          return FilterChip(
                              label: Text(p.replaceAll('_', ' '),
                                  style: const TextStyle(fontSize: 11)),
                              selected: sel,
                              onSelected: (v) => setDialogState(() {
                                    if (v) {
                                      selectedPrivs.add(p);
                                    } else {
                                      selectedPrivs.remove(p);
                                    }
                                  }),
                              selectedColor: const Color(0xFF4F46E5));
                        }).toList()),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                setDialogState(() => saving = true);
                                try {
                                  await AppwriteUserRepository
                                      .updatePrivilegesAndStatus(
                                          docId: docId,
                                          role: selectedRole,
                                          privileges: selectedPrivs,
                                          status: selectedStatus);
                                  final me = AppwriteAuthService.currentUser;
                                  final myId = me?.$id ?? '';
                                  if (myId.isNotEmpty && myId == docId.trim()) {
                                    // Editing the currently logged-in user:
                                    // refresh cache + notify router so the
                                    // dashboard redirect re-evaluates role.
                                    unawaited(
                                        AppwriteAuthService.refreshProfile());
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  setState(() {
                                    final idx = _localUsers.indexWhere((e) =>
                                        (e['id'] ?? e[r'$id'] ?? '')
                                            .toString() ==
                                        docId);
                                    if (idx != -1) {
                                      _localUsers[idx] = {
                                        ..._localUsers[idx],
                                        'role': selectedRole,
                                        'privileges':
                                            AppwriteUserRepository
                                                .privilegesToString(
                                                    selectedPrivs),
                                        'status': selectedStatus
                                      };
                                    }
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'User $name updated'),
                                            backgroundColor:
                                                const Color(0xFF00C805)));
                                  }
                                } catch (e) {
                                  if (!AppwriteService.isInitialized ||
                                      AppwriteUserRepository
                                          .isCollectionNotFound(e)) {
                                    setState(() {
                                      final idx = _localUsers.indexWhere(
                                          (e) =>
                                              (e['id'] ?? e[r'$id'] ?? '')
                                                  .toString() ==
                                              docId);
                                      if (idx != -1) {
                                        _localUsers[idx] = {
                                          ..._localUsers[idx],
                                          'role': selectedRole,
                                          'privileges':
                                              AppwriteUserRepository
                                                  .privilegesToString(
                                                      selectedPrivs),
                                          'status': selectedStatus
                                        };
                                      }
                                    });
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'User $name updated locally'),
                                              backgroundColor:
                                                  const Color(0xFF00C805)));
                                    }
                                  } else {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                              content: Text('Failed: $e'),
                                              backgroundColor:
                                                  const Color(0xFFDC2626)));
                                    }
                                  }
                                } finally {
                                  setDialogState(() => saving = false);
                                }
                              },
                        icon: saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded, size: 16),
                        label: Text(saving ? 'Saving...' : 'Save changes'),
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5)),
                      )),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'customer';
    String status = 'active';
    List<String> privs = [];
    bool saving = false;
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.person_add_rounded,
                                size: 18, color: Color(0xFF4F46E5))),
                        const SizedBox(width: 10),
                        const Text('Add User',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0B0E0F))),
                        const Spacer(),
                        IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx)),
                      ]),
                      const SizedBox(height: 4),
                      const Text(
                          'Directly introduce user to database with privileges & status',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                              labelText: 'Name *',
                              prefixIcon: const Icon(Icons.person_rounded,
                                  size: 18),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name required'
                              : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: emailCtrl,
                          decoration: InputDecoration(
                              labelText: 'Email *',
                              prefixIcon: const Icon(
                                  Icons.alternate_email_rounded,
                                  size: 18),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Valid email required'
                              : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: phoneCtrl,
                          decoration: InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: const Icon(Icons.phone_rounded,
                                  size: 18),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: DropdownButtonFormField<String>(
                                value: role,
                                decoration: const InputDecoration(
                                    labelText: 'Role *',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)))),
                                items: AppwriteUserRepository.allRoles
                                    .map((r) => DropdownMenuItem(
                                        value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (v) => setDialogState(() {
                                      role = v ?? 'user';
                                      privs = privs
                                          .where((p) =>
                                              AppwriteUserRepository
                                                  .privilegesForRole(role)
                                                  .contains(p))
                                          .toList();
                                    }))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: DropdownButtonFormField<String>(
                                value: status,
                                decoration: const InputDecoration(
                                    labelText: 'Status *',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)))),
                                items: AppwriteUserRepository.allStatuses
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) => setDialogState(
                                    () => status = v ?? 'active'))),
                      ]),
                      const SizedBox(height: 12),
                      const Text('Privileges',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151))),
                      const SizedBox(height: 6),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppwriteUserRepository.privilegesForRole(role).map((p) {
                            final sel = privs.contains(p);
                            return FilterChip(
                                label: Text(p.replaceAll('_', ' '),
                                    style: const TextStyle(fontSize: 11)),
                                selected: sel,
                                onSelected: (v) => setDialogState(() {
                                      if (v) {
                                        privs.add(p);
                                      } else {
                                        privs.remove(p);
                                      }
                                    }),
                                selectedColor: const Color(0xFF4F46E5),
                                backgroundColor: const Color(0xFFF9FAFB));
                          }).toList()),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: FilledButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) return;
                                  setDialogState(() => saving = true);
                                  try {
                                    final userId =
                                        'user_${DateTime.now().millisecondsSinceEpoch}';
                                    final doc =
                                        await AppwriteUserRepository.create(
                                            userId: userId,
                                            name: nameCtrl.text.trim(),
                                            email: emailCtrl.text.trim(),
                                            phone: phoneCtrl.text.trim(),
                                            role: role,
                                            privileges: privs,
                                            status: status);
                                    if (doc != null && ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                    final newUser = doc ??
                                        {
                                          'id': userId,
                                          r'$id': userId,
                                          'userId': userId,
                                          'name': nameCtrl.text.trim(),
                                          'email': emailCtrl.text.trim(),
                                          'phone': phoneCtrl.text.trim(),
                                          'role': role,
                                          'privileges': AppwriteUserRepository
                                              .privilegesToString(privs),
                                          'status': status,
                                          'emailVerification': false,
                                          'phoneVerification': false,
                                          r'$createdAt':
                                              DateTime.now().toIso8601String(),
                                        };
                                    setState(() {
                                      _localUsers.insert(0, newUser);
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'User ${nameCtrl.text.trim()} added to database'),
                                              backgroundColor:
                                                  const Color(0xFF00C805)));
                                    }
                                  } catch (e) {
                                    if (!AppwriteService.isInitialized ||
                                        AppwriteUserRepository
                                            .isCollectionNotFound(e)) {
                                      final userId =
                                          'user_${DateTime.now().millisecondsSinceEpoch}';
                                      final newUser = {
                                        'id': userId,
                                        r'$id': userId,
                                        'userId': userId,
                                        'name': nameCtrl.text.trim(),
                                        'email': emailCtrl.text.trim(),
                                        'phone': phoneCtrl.text.trim(),
                                        'role': role,
                                        'privileges':
                                            AppwriteUserRepository
                                                .privilegesToString(privs),
                                        'status': status,
                                        'emailVerification': false,
                                        'phoneVerification': false,
                                        r'$createdAt':
                                            DateTime.now().toIso8601String(),
                                      };
                                      setState(
                                          () => _localUsers.insert(0, newUser));
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      final isMissing =
                                          AppwriteUserRepository
                                              .isCollectionNotFound(e);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                content: Text(isMissing
                                                    ? 'Users collection missing — added locally. Run setup_appwrite.dart to create it.'
                                                    : 'User ${nameCtrl.text.trim()} added locally (demo)'),
                                                backgroundColor: isMissing
                                                    ? const Color(0xFFF59E0B)
                                                    : const Color(0xFF00C805),
                                                duration: Duration(
                                                    seconds:
                                                        isMissing ? 5 : 2)));
                                      }
                                    } else {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(
                                                content: Text('Failed: $e'),
                                                backgroundColor:
                                                    const Color(0xFFDC2626)));
                                      }
                                    }
                                  } finally {
                                    setDialogState(() => saving = false);
                                  }
                                },
                          icon: saving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.person_add_rounded, size: 16),
                          label: Text(
                              saving ? 'Adding...' : 'Add to Database'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5)),
                        )),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceUsers = _sourceUsers;
    final filtered = _filteredUsers;
    final counts = {
      'all': filtered.length,
      'admin': filtered.where((u) => u['role'] == 'admin').length,
      'customer': filtered.where((u) => u['role'] == 'customer').length,
      'active': filtered.where((u) => u['status'] == 'active').length,
      'pending': filtered.where((u) => u['status'] == 'pending').length,
      'blocked': filtered.where((u) => u['status'] == 'blocked').length,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Users (${sourceUsers.length})',
          action: 'Add User',
          onTap: _showAddUserDialog,
        ),
        if (AppwriteService.isInitialized)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A))),
            child: const Row(children: [
              Icon(Icons.info_rounded, size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Tip: If you see "collection_not_found" for users, create the "users" collection: Appwrite Console → Databases → hari_om_db → Collections → New (ID: users) or run dart run appwrite/setup_appwrite.dart',
                      style:
                          TextStyle(fontSize: 11, color: Color(0xFF92400E)))),
            ]),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            StatCard(
                label: 'Total Users',
                value: '${sourceUsers.length}',
                icon: Icons.group_rounded,
                color: const Color(0xFF4F46E5),
                bg: const Color(0xFFEEF2FF)),
            StatCard(
                label: 'Active',
                value: '${counts['active'] ?? 0}',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF059669),
                bg: const Color(0xFFECFDF5)),
            StatCard(
                label: 'Admins',
                value: '${counts['admin'] ?? 0}',
                icon: Icons.shield_rounded,
                color: const Color(0xFF7C3AED),
                bg: const Color(0xFFF5F3FF)),
            StatCard(
                label: 'Customers',
                value: '${counts['customer'] ?? 0}',
                icon: Icons.people_rounded,
                color: const Color(0xFF00C805),
                bg: const Color(0xFFECFDF5)),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final e in {
                'all': 'All',
                'admin': 'Admins',
                'customer': 'Customers'
              }.entries)
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                        label: Text(
                            '${e.value} (${e.key == 'all' ? filtered.length : filtered.where((u) => u['role'] == e.key).length})',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: _userRoleFilter == e.key
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _userRoleFilter == e.key
                                    ? Colors.white
                                    : const Color(0xFF374151))),
                        selected: _userRoleFilter == e.key,
                        onSelected: (_) =>
                            setState(() => _userRoleFilter = e.key),
                        selectedColor: const Color(0xFF4F46E5),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                            color: _userRoleFilter == e.key
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100)),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap)),
              const SizedBox(width: 12),
              for (final e in {
                'all': 'All status',
                'active': 'Active',
                'pending': 'Pending',
                'blocked': 'Blocked'
              }.entries)
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                        label: Text(e.value,
                            style: TextStyle(
                                fontSize: 11,
                                color: _userStatusFilter == e.key
                                    ? Colors.white
                                    : const Color(0xFF6B7280))),
                        selected: _userStatusFilter == e.key,
                        onSelected: (_) =>
                            setState(() => _userStatusFilter = e.key),
                        selectedColor: const Color(0xFF00C805))),
            ])),
        const SizedBox(height: 12),
        TextField(
            onChanged: (v) => setState(() => _userSearch = v),
            decoration: InputDecoration(
                hintText: 'Search by name, email or phone…',
                prefixIcon:
                    const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _userSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () =>
                            setState(() => _userSearch = ''))
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF4F46E5), width: 1.4)))),
        const SizedBox(height: 12),
        Text('Showing ${filtered.length} users',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(children: [
                Icon(Icons.person_off_rounded,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('No users found',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13)),
                const SizedBox(height: 6),
                Text('Try a different filter',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12)),
              ])),
        if (filtered.isNotEmpty && widget.isMobile)
          ...filtered.map((u) => UserCard(
              user: u,
              onTap: widget.onUserTap != null
                  ? () => widget.onUserTap!(u)
                  : () => _showUserDialog(u))),
        if (filtered.isNotEmpty && !widget.isMobile)
          AdminDataTable(
              columns: const [
                'Avatar',
                'User',
                'Role',
                'Privileges',
                'Status',
                'Joined',
                ''
              ],
              rows: filtered.map((u) {
                final name = (u['name'] ?? '—').toString();
                final email = (u['email'] ?? '').toString();
                final role = (u['role'] ?? 'customer').toString();
                final status = (u['status'] ?? 'active').toString();
                final isAdmin = role == 'admin';
                final joined = _formatDate(u[r'$createdAt'] ?? u['created_at']);
                return [
                  isAdmin ? 'ADMIN' : name[0].toUpperCase(),
                  '$name\n$email',
                  isAdmin ? 'ADMIN' : 'CUSTOMER',
                  '${AppwriteUserRepository.privilegesOf(u).length}',
                  status.toUpperCase(),
                  joined,
                  '→'
                ];
              }).toList(),
              emptyMessage: 'No users found',
              statusColumnIndex: 4,
              onRowTap: (idx) {
                if (idx < filtered.length) {
                  final u = filtered[idx];
                  if (widget.onUserTap != null) {
                    widget.onUserTap!(u);
                  } else {
                    _showUserDialog(u);
                  }
                }
              }),
      ],
    );
  }
}
