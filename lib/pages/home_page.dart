import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/company_info.dart';
import '../services/scroll_manager.dart';
import '../services/subscription_service.dart';
import '../widgets/app_header.dart';

/// Home page for Organic Jaggery manufacturer.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(title: 'Hari Om Traders', subtitle: 'Organic Jaggery \u2022 hariomtraders.com'),
      body: HomeContent(),
    );
  }
}

/// Content-only version for tab navigation – Organic Jaggery manufacturing context.
/// Modern website feel: centered max-width, generous whitespace, card elevation,
/// bento grids, soft gradients, responsive.
///
/// Scroll is preserved via [ScrollManager] (`home` key) + [PageStorageKey]
/// so browser back / tab switch restores exact offset instead of jumping to top.
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  static const double _maxW = 1180;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  static const _scrollKey = 'home';
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollManager.instance.controllerFor(_scrollKey);
    // also keep PageStorage bucket in sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final saved = ScrollManager.instance.getOffset(_scrollKey);
        if ((_scrollCtrl.offset - saved).abs() > 1) {
          _scrollCtrl.jumpTo(saved.clamp(0, _scrollCtrl.position.maxScrollExtent));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;

    return CustomScrollView(
      key: const PageStorageKey<String>(_scrollKey),
      controller: _scrollCtrl,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: bg,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: HomeContent._maxW),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroSection(isDark: isDark),
                      const SizedBox(height: 20),
                      _TrustBar(isDark: isDark),
                      const SizedBox(height: 36),
                      _SectionHeader(
                        eyebrow: 'Why we’re different',
                        title: 'Why our jaggery hits different',
                        subtitle:
                            'Small-batch, wood-pressed, lab-tested. We keep the minerals in and the chemicals out — so you taste the farm, not the factory.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),
                      _FeaturesBento(isDark: isDark),
                      const SizedBox(height: 28),
                      _StatsStrip(isDark: isDark),
                      const SizedBox(height: 36),
                      _SectionHeader(
                        eyebrow: 'From cane to cube',
                        title: 'Our process, fully transparent',
                        subtitle: '48 hours from harvest to pack. Traditional chulha, iron kadhai, zero sulphur.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),
                      _ProcessTimeline(isDark: isDark),
                      const SizedBox(height: 36),
                      _SectionHeader(
                        eyebrow: 'Bestsellers',
                        title: 'Featured jaggery',
                        subtitle: 'Hand-picked by 10,000+ families. Tap to explore the full range.',
                        isDark: isDark,
                        action: TextButton(
                          onPressed: () {
                            try {
                              GoRouter.of(context).go('/products');
                            } catch (_) {}
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [Text('View all'), SizedBox(width: 4), Icon(Icons.arrow_outward, size: 16)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FeaturedCarousel(isDark: isDark),
                      const SizedBox(height: 36),
                      _TestimonialsSection(isDark: isDark),
                      const SizedBox(height: 36),
                      _FarmCTA(isDark: isDark),
                      const SizedBox(height: 24),
                      _NewsletterCTA(isDark: isDark),
                      const SizedBox(height: 32),
                      _MiniFooter(isDark: isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── HERO ─────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final isDesktop = c.maxWidth > 860;
      final heroCard = Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14181B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.30 : 0.06), blurRadius: 32, offset: const Offset(0, 12)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isDesktop
            ? Row(
                children: [
                  Expanded(flex: 11, child: _HeroCopy(isDark: isDark)),
                  Expanded(flex: 10, child: _HeroVisual(isDark: isDark)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroCopy(isDark: isDark),
                  _HeroVisual(isDark: isDark, height: 300),
                ],
              ),
      );

      return Column(
        children: [
          // top announcement pill – responsive, wraps on <360
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: c.maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2620) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: isDark ? const Color(0xFF2A3A2E) : const Color(0xFFDCFCE7)),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(100)),
                    child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: c.maxWidth - 100),
                    child: Text('Winter harvest is here — free shipping over ₹499',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF14532D),
                        )),
                  ),
                  Icon(Icons.arrow_forward, size: 14, color: isDark ? Colors.white70 : const Color(0xFF14532D)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          heroCard,
        ],
      );
    });
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C805).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00C805).withOpacity(0.18)),
                ),
                child: const Icon(Icons.spa, color: Color(0xFF00C805), size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('PURE  •  ORGANIC  •  UNREFINED',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: const Color(0xFF00C805),
                      )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // headline with gradient accent – responsive font (280px -> 28, 1200 -> 38)
          LayoutBuilder(builder: (context, cc) {
            final double fs = cc.maxWidth < 340 ? 26 : cc.maxWidth < 380 ? 28 : cc.maxWidth < 600 ? 32 : 38;
            return RichText(
              text: TextSpan(
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: fs,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: isDark ? Colors.white : const Color(0xFF0B0E0F),
                ),
                children: [
                  const TextSpan(text: 'Organic jaggery\n'),
                  TextSpan(
                    text: 'from farm to family.',
                    style: TextStyle(
                      foreground: Paint()
                        ..shader = const LinearGradient(colors: [Color(0xFF00C805), Color(0xFF0E8A3E)]).createShader(const Rect.fromLTWH(0, 0, 300, 40)),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
          Text(
            'We make 15+ varieties of certified organic jaggery — wood-pressed from hand-harvested sugarcane. No chemicals. No sulphur. Just slow-boiled sweetness.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () {
                  try {
                    GoRouter.of(context).go('/products');
                  } catch (_) {}
                },
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: const Text('Shop jaggery'),
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : const Color(0xFF0B0E0F),
                  foregroundColor: isDark ? const Color(0xFF0B0E0F) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  try {
                    GoRouter.of(context).go('/content/our-process');
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Our traditional wood-pressed process — 4 steps from harvest to pack')));
                  }
                },
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('See how it’s made'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF0B0E0F),
                  side: BorderSide(color: isDark ? const Color(0xFF2A2E32) : const Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFF0F0F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // avatar stack
                SizedBox(
                  width: 72,
                  height: 28,
                  child: Stack(children: [
                    for (int i = 0; i < 3; i++)
                      Positioned(
                        left: i * 18,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF14181B) : Colors.white, width: 2),
                            color: [const Color(0xFFFEF3C7), const Color(0xFFD1FAE5), const Color(0xFFE0E7FF)][i],
                          ),
                          child: Icon([Icons.person, Icons.eco, Icons.favorite][i], size: 14, color: const Color(0xFF374151)),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      for (int i = 0; i < 5; i++) const Icon(Icons.star, size: 11, color: Color(0xFFFFB020)),
                      const SizedBox(width: 4),
                      Flexible(child: Text('4.8/5', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 11))),
                    ]),
                  Text('Trusted by 10,000+ families',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 11)),
                ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.isDark, this.height});
  final bool isDark;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final h = height ?? 460.0;
    return SizedBox(
      height: h,
      child: LayoutBuilder(builder: (context, bc) {
        final tiny = bc.maxWidth < 340;
        return Stack(
          fit: StackFit.expand,
          children: [
            // image
            ClipRRect(
              borderRadius: height != null ? BorderRadius.zero : const BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28)),
              child: Image.asset(
                'assets/img/unit.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3F4F6)),
                ),
              ),
            ),
            // soft gradient veil
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.28)],
                ),
                borderRadius: height != null ? BorderRadius.zero : const BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
            ),
            // floating stat cards – hide second on very narrow to prevent overflow, scale down
            if (!tiny)
              Positioned(
                left: 14,
                bottom: 14,
                child: _FloatCard(
                  icon: Icons.verified_rounded,
                  iconBg: const Color(0xFF00C805),
                  title: 'Certified Organic',
                  subtitle: 'NPOP • FSSAI • Lab tested',
                  isDark: isDark,
                ),
              ),
            if (!tiny)
              Positioned(
                right: 14,
                top: 14,
                child: _FloatCard(
                  icon: Icons.local_fire_department_rounded,
                  iconBg: const Color(0xFFEA580C),
                  title: 'Wood-pressed',
                  subtitle: 'No sulphur • Iron kadhai',
                  isDark: isDark,
                  small: true,
                ),
              ),
            // bottom-right card hides on tiny (<340) to avoid covering image too much
            if (bc.maxWidth >= 300)
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.water_drop, color: Color(0xFFD97706), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('5 ton / day', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0B0E0F))),
                        Text('Small-batch • Fresh', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ]),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _FloatCard extends StatelessWidget {
  const _FloatCard({required this.icon, required this.iconBg, required this.title, required this.subtitle, required this.isDark, this.small = false});
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 10 : 12, vertical: small ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 32 : 36,
            height: small ? 32 : 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: small ? 16 : 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: small ? 12 : 13, color: const Color(0xFF0B0E0F))),
            Text(subtitle, style: TextStyle(fontSize: small ? 10.5 : 11, color: const Color(0xFF6B7280))),
          ]),
        ],
      ),
    );
  }
}

// ───────────────────────── TRUST BAR ─────────────────────────

class _TrustBar extends StatelessWidget {
  const _TrustBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      ('Certified Organic', Icons.eco_outlined),
      ('FSSAI Licensed', Icons.verified_outlined),
      ('Lab Tested', Icons.science_outlined),
      ('500+ Farmers', Icons.agriculture_outlined),
      ('Pan-India 48h', Icons.local_shipping_outlined),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final isNarrow = c.maxWidth < 700;
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 8,
          spacing: 12,
          children: [
            Row(children: [
              Text('TRUSTED FOR PURITY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                    fontSize: 10,
                  )),
              const SizedBox(width: 10),
              Container(height: 16, width: 1, color: isDark ? const Color(0xFF2A2E32) : const Color(0xFFE5E7EB)),
            ]),
            ...items.map((e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.$2, size: 16, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(e.$1, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF374151))),
                    if (!isNarrow) const SizedBox(width: 14),
                  ],
                )),
          ],
        );
      }),
    );
  }
}

// ───────────────────────── SECTION HEADER ─────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.eyebrow, required this.title, required this.subtitle, required this.isDark, this.action});
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final isNarrow = c.maxWidth < 520;
      final content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2620) : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: isDark ? const Color(0xFF2A3A2E) : const Color(0xFFD1FAE5)),
          ),
          child: Text(eyebrow.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 10,
                color: const Color(0xFF00A63E),
              )),
        ),
        const SizedBox(height: 10),
        Text(title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              fontSize: c.maxWidth < 360 ? 20 : 24,
              color: isDark ? Colors.white : const Color(0xFF0B0E0F),
              height: 1.1,
            )),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280), height: 1.5)),
      ]);
      if (action == null) return content;
      if (isNarrow) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [content, const SizedBox(height: 10), Align(alignment: Alignment.centerLeft, child: action!)]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: content),
          const SizedBox(width: 16),
          Flexible(child: action!),
        ],
      );
    });
  }
}

// ───────────────────────── FEATURES BENTO ─────────────────────────

class _FeaturesBento extends StatelessWidget {
  const _FeaturesBento({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cross = w >= 1000 ? 3 : w >= 620 ? 2 : 1;
      // Aspect ratio adapts to narrow & short landscape – prevents vertical overflow
      double aspect;
      if (cross == 1) {
        aspect = w < 340 ? 1.9 : 2.1;
      } else if (cross == 2) {
        aspect = w < 700 ? 1.2 : 1.35;
      } else {
        aspect = 1.28;
      }
      final h = MediaQuery.sizeOf(context).height;
      if (h < 500) aspect = aspect * 0.9; // shorter screen -> slightly taller cards
      const items = [
        _FeatureData('100-organic', Icons.eco_rounded, '100% Organic', 'Certified cane, zero pesticides. Grown with cow-dung manure & neem.', Color(0xFF00C805), 'NPOP certified'),
        _FeatureData('wood-pressed', Icons.local_fire_department_rounded, 'Wood-Pressed', 'Juice slow-pressed, boiled in iron kadhai over wood fire — no sulphur.', Color(0xFFEA580C), 'Traditional chulha'),
        _FeatureData('iron-rich', Icons.favorite_rounded, 'Iron Rich', 'Natural iron & minerals retained. Not refined, not bleached.', Color(0xFFDC2626), '12 mg / 100g'),
        _FeatureData('farmer-direct', Icons.handshake_rounded, 'Farmer Direct', 'Fair price to 500+ farmers in Eastern UP. You support a village.', Color(0xFF2563EB), 'Since 2018'),
        _FeatureData('lab-tested', Icons.science_rounded, 'Lab Tested', 'Every batch tested for sulphur, sweetness & purity before packing.', Color(0xFF7C3AED), 'COA with QR'),
        _FeatureData('pan-india-48h', Icons.bolt_rounded, 'Pan-India 48h', 'Fresh-packed, shipped within 24h. Hygienic pouch + jar.', Color(0xFF0891B2), 'Free over ₹499'),
      ];
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: aspect,
        ),
        itemBuilder: (_, i) => _ModernFeatureCard(data: items[i], isDark: isDark),
      );
    });
  }
}

class _FeatureData {
  const _FeatureData(this.slug, this.icon, this.title, this.subtitle, this.accent, this.badge);
  final String slug;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String badge;
}

class _ModernFeatureCard extends StatelessWidget {
  const _ModernFeatureCard({required this.data, required this.isDark});
  final _FeatureData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.18 : 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(builder: (context, cc) {
        final cw = cc.maxWidth;
        final iconSz = (cw * 0.13).clamp(28.0, 42.0);
        final iconInner = (cw * 0.06).clamp(14.0, 20.0);
        final badgeFont = (cw * 0.028).clamp(8.0, 11.0);
        final badgeHPad = (cw * 0.03).clamp(6.0, 10.0);
        final badgeVPad = (cw * 0.012).clamp(2.5, 5.0);
        final titleFont = (cw * 0.048).clamp(13.0, 17.0);
        final subtitleFont = (cw * 0.036).clamp(10.0, 13.0);
        final learnFont = (cw * 0.032).clamp(9.0, 12.0);
        final learnIcon = (cw * 0.036).clamp(10.0, 14.0);
        final tiny = cw < 140;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: iconSz,
              height: iconSz,
              decoration: BoxDecoration(color: data.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(iconSz * 0.32)),
              child: Icon(data.icon, color: data.accent, size: iconInner),
            ),
            const Spacer(),
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: badgeHPad, vertical: badgeVPad),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2429) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: isDark ? const Color(0xFF2A2E32) : const Color(0xFFE5E7EB)),
                ),
                child: Text(data.badge, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: badgeFont, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
              ),
            ),
          ]),
          SizedBox(height: cw * 0.04),
          Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: tiny ? titleFont * 0.85 : titleFont, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
          SizedBox(height: cw * 0.015),
          Flexible(
            child: Text(data.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(height: 1.4, color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: subtitleFont)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/feature/${data.slug}'),
            behavior: HitTestBehavior.opaque,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Learn more', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: data.accent, fontSize: learnFont)),
              SizedBox(width: cw * 0.012),
              Icon(Icons.arrow_outward, size: learnIcon, color: data.accent),
            ]),
          ),
        ]);
      }),
    );
  }
}

// ───────────────────────── STATS STRIP ─────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = [
      ('15+', 'Jaggery varieties', 'Powder to chikki'),
      ('500+', 'Partner farmers', 'Eastern UP belt'),
      ('10k+', 'Happy families', '4.8★ avg rating'),
      ('5T', 'Pressed daily', 'Wood-fired unit'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E0F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: LayoutBuilder(builder: (context, c) {
        final isNarrow = c.maxWidth < 560;
        final isTiny = c.maxWidth < 340;
        return isNarrow
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: isTiny ? 1.5 : 1.9, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemBuilder: (_, i) => _StatCell(data: stats[i], theme: theme),
              )
            : Row(
                children: [
                  for (int i = 0; i < stats.length; i++) ...[
                    Expanded(child: _StatCell(data: stats[i], theme: theme)),
                    if (i != stats.length - 1) Container(width: 1, height: 48, color: Colors.white.withOpacity(0.10)),
                  ],
                ],
              );
      }),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.data, required this.theme});
  final (String, String, String) data;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final tiny = w < 340;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: tiny ? 10 : 14, vertical: tiny ? 10 : 14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(data.$1, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: tiny ? 18 : 22, letterSpacing: -0.8)),
          const SizedBox(height: 2),
          Text(data.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: tiny ? 11 : 12)),
          Text(data.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: tiny ? 10 : 11)),
        ]),
      ),
    );
  }
}

// ───────────────────────── PROCESS TIMELINE ─────────────────────────

class _ProcessTimeline extends StatelessWidget {
  const _ProcessTimeline({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final isDesktop = c.maxWidth > 800;
      final steps = [
        _StepData('01', 'Harvest', 'Organic cane hand-cut at 12 months. No burning, no machines.', Icons.agriculture_rounded, const Color(0xFF00C805)),
        _StepData('02', 'Press', 'Wood-pressed juice, double filtered through muslin.', Icons.water_drop_rounded, const Color(0xFF2563EB)),
        _StepData('03', 'Boil', 'Slow boiled 4 hrs in iron kadhai over wood chulha. No sulphur.', Icons.local_fire_department_rounded, const Color(0xFFEA580C)),
        _StepData('04', 'Pack', 'Hygienic pack in food-grade pouch/jar. QR-linked lab report.', Icons.inventory_2_rounded, const Color(0xFF7C3AED)),
      ];

      if (isDesktop) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14181B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(child: _StepCard(data: steps[i], isDark: isDark, theme: theme)),
                if (i != steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: Container(
                      width: 28,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [steps[i].accent.withOpacity(0.5), steps[i + 1].accent.withOpacity(0.5)]),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14181B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _StepCard(data: steps[i], isDark: isDark, theme: theme, horizontal: true),
              if (i != steps.length - 1)
                Container(
                  width: 2,
                  height: 18,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [steps[i].accent.withOpacity(0.5), steps[i + 1].accent.withOpacity(0.5)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }
}

class _StepData {
  const _StepData(this.num, this.title, this.subtitle, this.icon, this.accent);
  final String num;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.data, required this.isDark, required this.theme, this.horizontal = false});
  final _StepData data;
  final bool isDark;
  final ThemeData theme;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: data.accent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: data.accent.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Icon(data.icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: data.accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(data.num, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.6, color: data.accent)),
        ),
        const SizedBox(height: 6),
        Text(data.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
        const SizedBox(height: 4),
        Text(data.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45, color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 12),
            textAlign: horizontal ? TextAlign.start : TextAlign.center),
      ],
    );

    if (horizontal) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Flexible(child: content),
        const SizedBox(width: 12),
        const Expanded(child: SizedBox()),
      ]);
    }
    return content;
  }
}

// ───────────────────────── FEATURED CAROUSEL ─────────────────────────

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const items = [
      _ProdChip('Jaggery Powder', '500g • ₹199', 'assets/img/products/organic-granular-jaggery-1kg.png', Icons.grain_rounded, Color(0xFFFFF7ED), Color(0xFFEA580C)),
      _ProdChip('Peanut Chikki', '200g • ₹179', 'assets/img/products/organic-jaggery-peanut-chikki-200g.png', Icons.cookie_rounded, Color(0xFFF0FDF4), Color(0xFF16A34A)),
      _ProdChip('Kakvi Syrup', '500ml • ₹349', 'assets/img/products/organic-liquid-jaggery-kakvi-500ml.jpg', Icons.water_drop_rounded, Color(0xFFEFF6FF), Color(0xFF2563EB)),
      _ProdChip('Tea Blend', '100g • ₹299', 'assets/img/products/organic-jaggery-tea-blend-100g.jpg', Icons.local_cafe_rounded, Color(0xFFFEFCE8), Color(0xFFCA8A04)),
      _ProdChip('Gift Hamper', '1.5kg • ₹899', 'assets/img/products/organic-jaggery-gift-hamper-1-5kg.jpg', Icons.card_giftcard_rounded, Color(0xFFFAF5FF), Color(0xFF9333EA)),
      _ProdChip('With Ginger', '250g • ₹249', 'assets/img/products/organic-jaggery-ginger-250g.png', Icons.eco_rounded, Color(0xFFECFDF5), Color(0xFF059669)),
    ];

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              try {
                GoRouter.of(context).go('/products');
              } catch (_) {}
            },
            child: Container(
              width: 148,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14181B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.16 : 0.05), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  height: 76,
                  decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(p.asset, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) {
                          return Icon(p.icon, color: p.accent, size: 32);
                        }),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)]),
                          child: Text('₹${p.priceLabel.split('•').last.trim().replaceAll('₹', '')}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Color(0xFF0B0E0F))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(p.title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0B0E0F)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(p.priceLabel, style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 11)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _ProdChip {
  const _ProdChip(this.title, this.priceLabel, this.asset, this.icon, this.bg, this.accent);
  final String title;
  final String priceLabel;
  final String asset;
  final IconData icon;
  final Color bg;
  final Color accent;
}

// ───────────────────────── TESTIMONIALS ─────────────────────────

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.format_quote_rounded, color: const Color(0xFF00C805).withOpacity(0.30), size: 28),
          const SizedBox(width: 8),
          Text('Loved by families', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.1, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final cross = c.maxWidth > 900 ? 3 : c.maxWidth > 560 ? 2 : 1;
          const reviews = [
            ('Anjali S.', 'Mumbai', 'Switched from sugar to this kakvi for my kids’ milk. Dissolves instantly, no weird aftertaste. Subtle caramel, not too sweet.', 5),
            ('Rohit V.', 'Pune', 'Peanut chikki is dangerously good. Crunchy, not overly sweet, you can taste the jaggery. My gym snack now.', 5),
            ('Dr. Meena', 'Varanasi', 'As a nutritionist I recommend it — iron-rich, sulphur-free. The QR lab report builds real trust.', 5),
          ];
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: cross == 1 ? 1.9 : 1.25,
            ),
            itemBuilder: (_, i) {
              final r = reviews[i];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14181B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [for (int s = 0; s < (r.$4 as int); s++) const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB020))]),
                  const SizedBox(height: 10),
                  Expanded(child: Text('“${r.$3}”', style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: isDark ? Colors.white70 : const Color(0xFF374151), fontSize: 13))),
                  const SizedBox(height: 12),
                  Row(children: [
                    CircleAvatar(radius: 16, backgroundColor: const Color(0xFF00C805).withOpacity(0.14), child: Text((r.$1 as String)[0], style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF00A63E), fontSize: 12))),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.$1 as String, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 12)),
                      Text(r.$2 as String, style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white54 : const Color(0xFF9CA3AF), fontSize: 11)),
                    ]),
                    const Spacer(),
                    Icon(Icons.verified_rounded, size: 16, color: const Color(0xFF00C805).withOpacity(0.9)),
                  ]),
                ]),
              );
            },
          );
        }),
      ],
    );
  }
}

// ───────────────────────── FARM CTA ─────────────────────────

class _FarmCTA extends StatelessWidget {
  const _FarmCTA({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B0E0F), Color(0xFF1C2A1E)]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, c) {
        final isDesktop = c.maxWidth > 740;
        final text = Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withOpacity(0.14))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('VISIT OUR UNIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: 10)),
              ]),
            ),
            const SizedBox(height: 14),
            Text('Come see how jaggery\nis really made.',
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.6)),
            const SizedBox(height: 10),
            Text('${CompanyInfo.address}\n5 ton/day • Wood-pressed • Open Mon–Sat • Free tasting',
                style: TextStyle(color: Colors.white.withOpacity(0.72), height: 1.5, fontSize: 13)),
            const SizedBox(height: 18),
            Wrap(spacing: 10, children: [
              FilledButton.icon(
                onPressed: () {
                  try {
                    GoRouter.of(context).go('/contact');
                  } catch (_) {}
                },
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Get directions'),
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0B0E0F), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              ),
              OutlinedButton(
                onPressed: () {
                  try {
                    GoRouter.of(context).go('/contact');
                  } catch (_) {}
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                child: const Text('Book a tour'),
              ),
            ]),
          ]),
        );

        final image = Stack(
          children: [
            SizedBox(
              height: isDesktop ? 320 : 220,
              width: double.infinity,
              child: Image.asset('assets/img/sugarcane.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                return Image.asset('assets/img/organic-farm-hero.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                  return Container(color: const Color(0xFF1C2A1E));
                });
              }),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Text(CompanyInfo.shortAddress, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF0B0E0F))),
                ]),
              ),
            ),
          ],
        );

        if (isDesktop) {
          return Row(children: [Expanded(child: text), Expanded(child: image)]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [text, image]);
      }),
    );
  }
}

// ───────────────────────── NEWSLETTER ─────────────────────────

class _NewsletterCTA extends StatefulWidget {
  const _NewsletterCTA({required this.isDark});
  final bool isDark;

  @override
  State<_NewsletterCTA> createState() => _NewsletterCTAState();
}

class _NewsletterCTAState extends State<_NewsletterCTA> {
  final TextEditingController _emailCtrl = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;

  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  bool _isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

  Future<void> _validateAndJoin() async {
    // Prevent double-tap race
    if (_isSubmitting) return;
    final raw = _emailCtrl.text.trim();
    if (raw.isEmpty) {
      if (mounted) setState(() => _errorText = 'Please enter your email address');
      return;
    }
    if (!_isValidEmail(raw)) {
      if (mounted) setState(() => _errorText = 'Please enter a valid email address (e.g., name@example.com)');
      return;
    }
    // Clear previous error, show loading
    if (mounted) {
      setState(() {
        _errorText = null;
        _isSubmitting = true;
      });
    } else {
      return;
    }
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    try {
      // NEW FLOW: Do NOT insert directly into subscribers.
      // Create pending record + send verification email (24h expiry).
      String? baseUrl;
      if (kIsWeb) {
        try {
          baseUrl = Uri.base.origin;
        } catch (_) {}
      }
      final res = await SubscriptionService.instance
          .requestSubscription(email: raw, source: 'home_newsletter', baseUrl: baseUrl)
          .timeout(const Duration(seconds: 12), onTimeout: () => (success: false, alreadySubscribed: false, verificationSent: false, error: 'Network timeout — please check your connection and try again.', token: null));

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (!res.success) {
        final msg = res.error?.toLowerCase() ?? '';
        final friendly = msg.contains('timeout')
            ? 'Network timeout — please try again.'
            : (res.error ?? 'Something went wrong. Please try again.');
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(friendly),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      if (res.alreadySubscribed) {
        _emailCtrl.clear();
        if (_errorText != null && mounted) setState(() => _errorText = null);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('You’re already subscribed with $raw — thanks!'),
            backgroundColor: const Color(0xFF0B0E0F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      _emailCtrl.clear();
      if (_errorText != null && mounted) setState(() => _errorText = null);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: const Text('Verification link sent! Please check your inbox to confirm your subscription.'),
          backgroundColor: const Color(0xFF0B0E0F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e, st) {
      debugPrint('[NewsletterCTA] _validateAndJoin unhandled error: $e\n$st');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Could not join right now: ${e.toString().split('\n').first}. Please try again.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final isDesktop = c.maxWidth > 640;
        final form = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                onSubmitted: (_) => _validateAndJoin(),
                decoration: InputDecoration(
                  hintText: 'Your email',
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                  errorText: _errorText,
                  errorMaxLines: 2,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.4)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: Color(0xFFEF4444))),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _isSubmitting ? null : _validateAndJoin,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805), foregroundColor: Colors.white, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
              child: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Join', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );

        final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Get farm-fresh drops & offers',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
          const SizedBox(height: 4),
          Text('No spam. Unsubscribe anytime. 2× month max.', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
        ]);

        if (isDesktop) {
          return Row(children: [Expanded(child: copy), const SizedBox(width: 20), Expanded(child: form)]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: 14), form]);
      }),
    );
  }
}

// ───────────────────────── MINI FOOTER ─────────────────────────

class _MiniFooter extends StatelessWidget {
  const _MiniFooter({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = isDark ? Colors.white54 : const Color(0xFF9CA3AF);
    return Column(
      children: [
        Divider(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB), height: 1),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final isNarrow = c.maxWidth < 700;
          final left = Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Image.asset('assets/img/logo.png', width: 22, height: 22, errorBuilder: (_, __, ___) => const Icon(Icons.spa, size: 18, color: Color(0xFF00C805))),
              Text('Hari Om Traders', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
              Text('© 2026 hariomtraders.com', style: theme.textTheme.labelSmall?.copyWith(color: muted, fontSize: 11)),
            ],
          );
          final right = Wrap(spacing: 14, children: [
            _FooterLink(label: 'Privacy', onTap: () => GoRouter.of(context).go('/content/privacy')),
            _FooterLink(label: 'Terms', onTap: () => GoRouter.of(context).go('/content/terms')),
            _FooterLink(label: 'Shipping', onTap: () => GoRouter.of(context).go('/content/shipping')),
            _FooterLink(label: 'Contact', onTap: () => GoRouter.of(context).go('/contact')),
            _FooterLink(label: 'About us', onTap: () => GoRouter.of(context).go('/about')),
          ]);
          if (isNarrow) return Column(children: [left, const SizedBox(height: 10), right]);
          return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: left), const SizedBox(width: 12), Flexible(child: Align(alignment: Alignment.centerRight, child: right))]);
        }),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        ));
  }
}
