import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../appwrite/auth_service.dart';

/// Global theme controller – toggles light/dark for Hari Om Traders theme.
final ValueNotifier<ThemeMode> themeController = ValueNotifier(ThemeMode.light);

/// Tab routes fallback (0=Home, 1=Products, 2=Contact Us, 3=About Us) – used when a page
/// embeds [AppHeader] without wiring onNavSelected, so nav links always work.
const List<String> kNavRoutes = <String>['/', '/products', '/contact', '/about'];

/// Theme change button – used in Hari Om Traders header far right.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
          onPressed: () => themeController.value = isDark ? ThemeMode.light : ThemeMode.dark,
        );
      },
    );
  }
}

/// Hari Om Traders header – identical height/style to robinhood.com but branded for Hari Om Traders (Organic Jaggery).
/// - Height 64, white (light) / #0B0E0F (dark), 1px bottom border
/// - Left: logo.png from assets/img/logo.png + "Hari Om Traders" wordmark
/// - Center: nav links (Home / Products / Contact Us / About Us) styled like robinhood.com
/// - Right: "Log in" text, "Sign up" pill, theme toggle
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.titleWidget,
    this.showThemeToggle = true,
    this.navIndex,
    this.onNavSelected,
  });

  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final bool showThemeToggle;

  /// If provided, shows Hari Om Traders center nav and highlights selected index.
  /// Pass from AppShell: 0=Home, 1=Products, 2=Contact Us, 3=About Us
  final int? navIndex;
  final ValueChanged<int>? onNavSelected;

  static const _robinGreen = Color(0xFF00C805);
  static const _robinBlack = Color(0xFF0B0E0F);

  @override
  Size get preferredSize => Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? _robinBlack : Colors.white);
    final fg = foregroundColor ?? (isDark ? Colors.white : Colors.black);
    final borderColor = isDark ? const Color(0xFF2A2E32) : const Color(0xFFE7E5E0);
    final muted = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Material(
      color: bg,
      elevation: 0,
      child: Builder(
        builder: (context) {
          final currentPath = GoRouterState.of(context).matchedLocation;
          final effectiveNavIndex = navIndex ?? kNavRoutes.indexWhere((r) => currentPath == r || (r == '/about' && currentPath.startsWith('/about')));
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final isNarrow = c.maxWidth < 820;
                          final isVeryNarrow = c.maxWidth < 360;
                          final isTiny = c.maxWidth < 320;
                          return Row(
                            children: [
                              // Left: Hari Om Traders logo.png + wordmark
                              Flexible(
                                fit: FlexFit.loose,
                                child: InkWell(
                                  onTap: () {
                                    if (onNavSelected != null) onNavSelected!(0);
                                    context.go('/');
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset('assets/img/logo.png', width: isTiny ? 28 : isVeryNarrow ? 30 : 36, height: isTiny ? 28 : isVeryNarrow ? 30 : 36, fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Container(
                                                width: 28,
                                                height: 28,
                                                decoration: const BoxDecoration(color: _robinGreen, shape: BoxShape.circle),
                                                child: const Icon(Icons.spa, size: 16, color: Colors.white),
                                              )),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Hari Om Traders',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: isTiny ? 15 : isVeryNarrow ? 16 : 20,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                              color: fg,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isNarrow) const SizedBox(width: 32),
                              // Center nav
                              if (!isNarrow)
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _NavLink(label: 'Home', selected: effectiveNavIndex == 0, onTap: () { if (onNavSelected != null) { onNavSelected!(0); } else { context.go(kNavRoutes[0]); } }, fg: fg, muted: muted),
                                      const SizedBox(width: 28),
                                      _NavLink(label: 'Products', selected: effectiveNavIndex == 1, onTap: () { if (onNavSelected != null) { onNavSelected!(1); } else { context.go(kNavRoutes[1]); } }, fg: fg, muted: muted),
                                      const SizedBox(width: 28),
                                      _NavLink(label: 'About Us', selected: effectiveNavIndex == 3, onTap: () { if (onNavSelected != null) { onNavSelected!(3); } else { context.go(kNavRoutes[3]); } }, fg: fg, muted: muted),
                                      const SizedBox(width: 28),
                                      _NavLink(label: 'Contact Us', selected: effectiveNavIndex == 2, onTap: () { if (onNavSelected != null) { onNavSelected!(2); } else { context.go(kNavRoutes[2]); } }, fg: fg, muted: muted),
                                      const SizedBox(width: 28),
                                    ],
                                  ),
                                )
                              else
                                const Spacer(),
                              // Right side – Auth + theme + extra actions
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (!isNarrow && actions != null) Flexible(child: Row(mainAxisSize: MainAxisSize.min, children: actions!)),
                                  if (!isNarrow) const SizedBox(width: 8),
                                  if (!isNarrow)
                                    Flexible(
                                      child: ValueListenableBuilder(
                                        valueListenable: appwriteUserNotifier,
                                        builder: (context, user, _) {
                                          if (isNarrow) return const SizedBox.shrink();
                                          if (user != null) {
                                            final name = AppwriteAuthService.displayName;
                                            return Row(mainAxisSize: MainAxisSize.min, children: [
                                              if (!isNarrow) ...[
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(color: isDark?const Color(0xFF1A1F24):const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB))),
                                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                      CircleAvatar(radius: 12, backgroundColor: const Color(0xFF00C805), child: Text(name.isNotEmpty?name[0].toUpperCase():'U', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                                                      const SizedBox(width: 6),
                                                      Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg))),
                                                    ]),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              OutlinedButton(
                                                onPressed: () async { await AppwriteAuthService.signOut(); if(context.mounted) context.go('/'); },
                                                style: OutlinedButton.styleFrom(foregroundColor: fg, side: BorderSide(color: isDark?const Color(0xFF2A2E32):const Color(0xFFE5E7EB)), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                                                child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                              ),
                                            ]);
                                          }
                                          return Row(mainAxisSize: MainAxisSize.min, children: [
                                            TextButton(
                                              onPressed: () => context.go('/login'),
                                              style: TextButton.styleFrom(foregroundColor: fg, textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                              child: const Text('Log in'),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton(
                                              onPressed: () => context.go('/signup'),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: isDark ? Colors.white : Colors.black,
                                                foregroundColor: isDark ? Colors.black : Colors.white,
                                                shape: const StadiumBorder(),
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                              ),
                                              child: const Text('Sign up'),
                                            ),
                                          ]);
                                        },
                                      ),
                                    ),
                                  if (showThemeToggle) ...[
                                    const SizedBox(width: 4),
                                    ThemeToggleButton(key: ValueKey(isDark)),
                                  ],
                                  if (isNarrow) ...[
                                    const SizedBox(width: 4),
                                    ValueListenableBuilder(
                                      valueListenable: appwriteUserNotifier,
                                      builder: (context, user, _) {
                                        return PopupMenuButton<int>(
                                          icon: Icon(Icons.menu, color: fg),
                                          offset: const Offset(0, 48),
                                          onSelected: (v) {
                                            if (v == 10) { try{ context.go('/login'); } catch(_){} return; }
                                            if (v == 11) { try{ context.go('/signup'); } catch(_){} return; }
                                            if (v == 99) { AppwriteAuthService.signOut(); try{ context.go('/'); } catch(_){} return; }
                                            if (onNavSelected != null) {
                                              onNavSelected!(v);
                                            } else if (v >= 0 && v < kNavRoutes.length) {
                                              context.go(kNavRoutes[v]);
                                            }
                                          },
                                          itemBuilder: (_) {
                                            final items = <PopupMenuEntry<int>>[
                                              const PopupMenuItem(value: 0, child: Text('Home')),
                                              const PopupMenuItem(value: 1, child: Text('Products')),
                                              const PopupMenuItem(value: 2, child: Text('Contact Us')),
                                              const PopupMenuItem(value: 3, child: Text('About Us')),
                                            ];
                                            if (user != null) {
                                              items.add(const PopupMenuDivider());
                                              items.add(PopupMenuItem(value: 99, child: Row(children: [Icon(Icons.logout, size:16), SizedBox(width:8), Text('Log out')])));
                                            } else {
                                              items.addAll(const [
                                                PopupMenuDivider(),
                                                PopupMenuItem(value: 10, child: Text('Log in')),
                                                PopupMenuItem(value: 11, child: Text('Sign up')),
                                              ]);
                                            }
                                            return items;
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (bottom != null) bottom!,
            ],
          );
        },
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, this.selected = false, required this.onTap, required this.fg, required this.muted});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? fg : muted,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 2),
          Container(height: 2, width: 24, color: selected ? AppHeader._robinGreen : Colors.transparent),
        ],
      ),
    );
  }
}

/// Sliver variant – Hari Om Traders style (white/black, 64 collapsed)
class SliverAppHeader extends StatelessWidget {
  const SliverAppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.floating = true,
    this.pinned = true,
    this.expandedHeight = 120,
    this.backgroundColor,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool floating;
  final bool pinned;
  final double expandedHeight;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      floating: floating,
      pinned: pinned,
      expandedHeight: expandedHeight,
      backgroundColor: backgroundColor ?? (isDark ? const Color(0xFF0B0E0F) : Colors.white),
      surfaceTintColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/img/logo.png', width: 26, height: 26, errorBuilder: (_, __, ___) => Icon(Icons.spa, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(width: 8),
          Text('Hari Om Traders', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w800)),
        ],
      ),
      actions: actions,
    );
  }
}
