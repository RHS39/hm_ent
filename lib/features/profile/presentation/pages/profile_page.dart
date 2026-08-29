import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../appwrite/auth_service.dart';
import '../../../../widgets/app_header.dart';
import '../cubit/profile_cubit.dart';
import '../../domain/entities/address.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ProfileCubit(), child: const _ProfileView());
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = AppwriteAuthService.displayName.isEmpty ? 'Guest User' : AppwriteAuthService.displayName;
    final email = AppwriteAuthService.displayEmail.isEmpty ? 'guest@hariomtraders.com' : AppwriteAuthService.displayEmail;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
      appBar: AppBar(title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800))),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                child: Row(children: [
                  Stack(children: [
                    CircleAvatar(radius: 36, backgroundColor: const Color(0xFF00C805), child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))),
                    Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF0B0E0F), shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white))),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text(userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(100)), child: const Text('GOLD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E))))]),
                    const SizedBox(height: 2),
                    Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    Text('Member since 2023 • 12 orders', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),
              _Tile(icon: Icons.receipt_long_rounded, title: 'My Orders', subtitle: 'Track, return or review', onTap: () => context.go('/app/orders')),
              _Tile(icon: Icons.location_on_rounded, title: 'Saved Addresses', subtitle: '${state.addresses.length} addresses', onTap: () => _showAddresses(context, state)),
              _Tile(icon: Icons.credit_card_rounded, title: 'Payment Methods', subtitle: '${state.payments.length} saved', onTap: () => _showPayments(context, state)),
              _Tile(icon: Icons.favorite_rounded, title: 'Wishlist', subtitle: '${state.wishlist.length} items', onTap: () => context.go('/app/wishlist')),
              _Tile(icon: Icons.settings_rounded, title: 'Settings', subtitle: 'Dark mode, notifications, password', onTap: () => _showSettings(context, state)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                  onTap: () async { await AppwriteAuthService.signOut(); if (context.mounted) context.go('/login'); },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddresses(BuildContext context, ProfileState state) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => BlocProvider.value(value: context.read<ProfileCubit>(), child: _AddressesSheet()));
  }

  void _showPayments(BuildContext context, ProfileState state) {
    showModalBottomSheet(context: context, builder: (_) => BlocProvider.value(value: context.read<ProfileCubit>(), child: _PaymentsSheet()));
  }

  void _showWishlist(BuildContext context, ProfileState state) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => BlocProvider.value(value: context.read<ProfileCubit>(), child: _WishlistSheet()));
  }

  void _showSettings(BuildContext context, ProfileState state) {
    showModalBottomSheet(context: context, builder: (_) => BlocProvider.value(value: context.read<ProfileCubit>(), child: _SettingsSheet()));
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
      child: ListTile(leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF00C805).withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: const Color(0xFF00C805))), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))), trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)), onTap: onTap),
    );
  }
}

class _AddressesSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(100))),
              const SizedBox(height: 12),
              Row(children: [const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const Spacer(), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))]),
              const Divider(),
              ...state.addresses.map((a) => _AddressTile(address: a)),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { final id = DateTime.now().millisecondsSinceEpoch.toString(); context.read<ProfileCubit>().addAddress(AddressEntity(id: id, label: 'New', address: 'New Address, Varanasi', pincode: '221001')); }, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Add new address'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F)))),
            ]),
          ),
        );
      },
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address});
  final AddressEntity address;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(address.label, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (address.isDefault) ...[
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100)), child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF00A63E)))),
            ],
          ]),
          Text(address.address, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Text(address.pincode, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ])),
        IconButton(icon: const Icon(Icons.edit_rounded, size: 18), onPressed: () {}),
        IconButton(icon: const Icon(Icons.delete_rounded, size: 18, color: Color(0xFFDC2626)), onPressed: () => context.read<ProfileCubit>().removeAddress(address.id)),
      ]),
    );
  }
}

class _PaymentsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            const Divider(),
            ...state.payments.map((p) => ListTile(leading: Icon(p.type == 'card' ? Icons.credit_card_rounded : p.type == 'upi' ? Icons.qr_code_rounded : Icons.payments_rounded), title: Text(p.label, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(p.type.toUpperCase()), trailing: p.isDefault ? Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100)), child: const Text('Default', style: TextStyle(fontSize: 10, color: Color(0xFF00A63E))) ) : null)),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Add new card'))),
          ]),
        );
      },
    );
  }
}

class _WishlistSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        // Mock product names for wishlist ids
        final map = {'1': 'Chocolaty Gud 700g', '3': 'Liquid Jaggery Kakvi 500ml', '7': 'Jaggery Block 1kg'};
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('Wishlist', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            const Divider(),
            if (state.wishlist.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No favorites yet')),
            ...state.wishlist.map((id) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.spa, color: Color(0xFF00C805))), const SizedBox(width: 10), Expanded(child: Text(map[id] ?? 'Product $id', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))), TextButton(onPressed: () => context.read<ProfileCubit>().moveToCart(id), child: const Text('Move to Cart')), IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => context.read<ProfileCubit>().toggleWishlist(id))]))),
          ]),
        );
      },
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            const Divider(),
            SwitchListTile(value: Theme.of(context).brightness == Brightness.dark, onChanged: (v) => themeController.value = v ? ThemeMode.dark : ThemeMode.light, title: const Text('Dark mode'), secondary: const Icon(Icons.dark_mode_rounded), activeColor: const Color(0xFF00C805)),
            SwitchListTile(value: state.notifications, onChanged: (v) => context.read<ProfileCubit>().toggleNotifications(v), title: const Text('Notifications'), secondary: const Icon(Icons.notifications_rounded), activeColor: const Color(0xFF00C805)),
            ListTile(leading: const Icon(Icons.lock_rounded), title: const Text('Change password'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _showChangePassword(context)),
          ]),
        );
      },
    );
  }

  void _showChangePassword(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true, obscureNew = true;
    bool busy = false;
    String? error;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) {
        Future<void> submit() async {
          final n = newCtrl.text.trim();
          final c = confirmCtrl.text.trim();
          final o = oldCtrl.text.trim();
          if (n.length < 8) { setSt(() => error = 'Password must be at least 8 characters'); return; }
          if (n != c) { setSt(() => error = 'Passwords do not match'); return; }
          setSt(() { busy = true; error = null; });
          final res = await AppwriteAuthService.updatePassword(newPassword: n, oldPassword: o.isEmpty ? null : o);
          if (!ctx.mounted) return;
          setSt(() => busy = false);
          if (res.ok) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
          } else {
            setSt(() => error = res.message);
          }
        }
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(color: Theme.of(ctx).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(100))),
              const SizedBox(height: 12),
              const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              if (error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))), child: Text(error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13))),
              TextField(controller: oldCtrl, obscureText: obscureOld, decoration: InputDecoration(labelText: 'Current password (if set)', suffixIcon: IconButton(icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setSt(() => obscureOld = !obscureOld)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: newCtrl, obscureText: obscureNew, decoration: InputDecoration(labelText: 'New password', suffixIcon: IconButton(icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setSt(() => obscureNew = !obscureNew)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: confirmCtrl, obscureText: obscureNew, decoration: InputDecoration(labelText: 'Confirm new password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              FilledButton(onPressed: busy ? null : submit, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805), padding: const EdgeInsets.symmetric(vertical: 14), shape: const StadiumBorder()), child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w800))),
            ]),
          ),
        );
      }),
    );
  }
}
