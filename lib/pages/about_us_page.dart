import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../services/scroll_manager.dart';
import '../constants/company_info.dart';

double _r(double w, double pct, num min, num max) => (w * pct).clamp(min, max).toDouble();

BoxDecoration _cardDeco(bool isDark, double w, {double radius = 20}) => BoxDecoration(
      color: isDark ? const Color(0xFF14181B) : Colors.white,
      borderRadius: BorderRadius.circular(_r(w, 0.035, 16, radius)),
      border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE8E8E8)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.14 : 0.07), blurRadius: 20, offset: const Offset(0, 8))],
    );

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(title: 'Hari Om Traders', subtitle: 'About Us • hariomtraders.com'),
      body: AboutUsContent(),
    );
  }
}

class AboutUsContent extends StatefulWidget {
  const AboutUsContent({super.key});
  @override
  State<AboutUsContent> createState() => _AboutUsContentState();
}

class _AboutUsContentState extends State<AboutUsContent> {
  static const _scrollKey = 'about';
  late final ScrollController _scrollCtrl = ScrollManager.instance.controllerFor(_scrollKey);
  static const double _maxW = 1180;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final saved = ScrollManager.instance.getOffset(_scrollKey);
        if (saved > 0 && (_scrollCtrl.offset - saved).abs() > 1) _scrollCtrl.jumpTo(saved.clamp(0, _scrollCtrl.position.maxScrollExtent));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxW),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final hPad = _r(w, 0.04, 12, 16);
            final vPad = _r(w, 0.03, 10, 16);
            final gapS = _r(w, 0.025, 10, 14);
            final gapM = _r(w, 0.04, 18, 28);
            final gapL = _r(w, 0.05, 20, 32);
            return SingleChildScrollView(
              key: const PageStorageKey<String>(_scrollKey),
              controller: _scrollCtrl,
              padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, _r(w, 0.05, 20, 32)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _TopPill(isDark: isDark),
                SizedBox(height: gapS),
                _HeroAbout(isDark: isDark),
                SizedBox(height: gapS),
                _TrustBar(isDark: isDark),
                SizedBox(height: gapM),
                _SectionHeader(eyebrow: 'Who we are', title: 'Varanasi’s trusted jaggery makers since 2018', subtitle: 'Organic, wood-pressed, lab-tested. We keep the farm in the flavour — working directly with 500+ farmers in Eastern UP.', isDark: isDark),
                SizedBox(height: _r(w, 0.03, 12, 16)),
                _StoryAndMission(isDark: isDark),
                SizedBox(height: gapM),
                _StatsStrip(isDark: isDark),
                SizedBox(height: gapM),
                _SectionHeader(eyebrow: 'Our journey', title: 'From 1 farmer to 500 families', subtitle: 'Slow growth, honest trade, small batches. No shortcuts — just cane, fire and patience.', isDark: isDark),
                SizedBox(height: _r(w, 0.025, 10, 14)),
                _Timeline(isDark: isDark),
                SizedBox(height: gapM),
                _SectionHeader(eyebrow: 'What guides us', title: 'Values you can taste', subtitle: 'Three non-negotiables that decide every batch we pack.', isDark: isDark),
                SizedBox(height: _r(w, 0.025, 10, 14)),
                _ValuesBento(isDark: isDark),
                SizedBox(height: gapM),
                _SectionHeader(eyebrow: 'People behind purity', title: 'Meet the team', subtitle: 'Small team, big responsibility. From farm visits to lab reports — real people, real numbers.', isDark: isDark),
                SizedBox(height: _r(w, 0.025, 10, 14)),
                _TeamSection(isDark: isDark),
                SizedBox(height: gapM),
                _SectionHeader(eyebrow: 'Certified & compliant', title: 'Trust is printed on the pack', subtitle: 'Organisation credentials and product purity — every claim backed by a certificate & QR-linked lab report.', isDark: isDark),
                SizedBox(height: _r(w, 0.025, 10, 14)),
                _CertSection(isDark: isDark),
                SizedBox(height: gapL),
                _FarmCTA(isDark: isDark),
                SizedBox(height: _r(w, 0.03, 12, 16)),
                _ContactSnippet(isDark: isDark, theme: theme),
              ]),
            );
          }),
        ),
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: _r(w, 0.03, 12, 16), vertical: _r(w, 0.02, 8, 10)),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(_r(w, 0.035, 14, 16)), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
        child: Row(children: [
          Container(padding: EdgeInsets.symmetric(horizontal: _r(w, 0.02, 8, 10), vertical: _r(w, 0.01, 4, 6)), decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(100)), child: Text('ABOUT • VARANASI', style: TextStyle(color: Colors.white, fontSize: _r(w, 0.025, 9, 10.5), fontWeight: FontWeight.w800, letterSpacing: 0.6))),
          SizedBox(width: _r(w, 0.02, 8, 10)),
          Expanded(child: Text('Pure • 221313 • Mon–Sat 8am–6pm • Factory visits welcome', style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white70 : const Color(0xFF374151), fontWeight: FontWeight.w600, fontSize: _r(w, 0.03, 10, 11.5)), overflow: TextOverflow.ellipsis, maxLines: 1)),
          SizedBox(width: _r(w, 0.015, 6, 8)),
          Icon(Icons.verified_rounded, size: _r(w, 0.04, 14, 16), color: const Color(0xFF00C805).withOpacity(0.9)),
        ]),
      );
    });
  }
}

class _HeroAbout extends StatelessWidget {
  const _HeroAbout({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final isDesktop = w > 860;
      final radius = _r(w, 0.03, 18, 28);
      return Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(radius), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE8E8E8)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.30 : 0.06), blurRadius: 32, offset: const Offset(0, 12))]),
        clipBehavior: Clip.antiAlias,
        child: isDesktop
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 11, child: _HeroCopy(isDark: isDark)), Expanded(flex: 10, child: SizedBox(height: 380, child: _HeroVisual(isDark: isDark)))])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_HeroCopy(isDark: isDark), _HeroVisual(isDark: isDark)]),
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
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final pad = _r(w, 0.05, 20, 28);
      final titleSize = _r(w, 0.09, 24, 36);
      final bodySize = _r(w, 0.038, 13, 14.5);
      final iconSz = _r(w, 0.045, 16, 20);
      return Padding(
        padding: EdgeInsets.all(pad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: EdgeInsets.all(_r(w, 0.02, 7, 9)), decoration: BoxDecoration(color: const Color(0xFF00C805).withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF00C805).withOpacity(0.18))), child: Icon(Icons.spa, color: const Color(0xFF00C805), size: iconSz)),
            SizedBox(width: _r(w, 0.02, 8, 10)),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('PURE  •  ORGANIC  •  VILLAGE-MADE', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.4, color: const Color(0xFF00C805), fontSize: _r(w, 0.03, 10, 11.5))))),
          ]),
          SizedBox(height: _r(w, 0.04, 14, 18)),
          RichText(text: TextSpan(style: theme.textTheme.displaySmall?.copyWith(fontSize: titleSize, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -1.2, color: isDark ? Colors.white : const Color(0xFF0B0E0F)), children: [const TextSpan(text: 'We keep jaggery\n'), TextSpan(text: 'honest.', style: TextStyle(foreground: Paint()..shader = const LinearGradient(colors: [Color(0xFF00C805), Color(0xFF0E8A3E)]).createShader(const Rect.fromLTWH(0, 0, 300, 40))))])),
          SizedBox(height: _r(w, 0.03, 10, 14)),
          Text('Hari Om Traders is a Varanasi-based organic jaggery maker. We work directly with 500+ farmers, wood-press fresh cane and slow-boil in iron kadhai — no sulphur, no chemicals, no shortcuts.', style: theme.textTheme.bodyMedium?.copyWith(height: 1.65, color: isDark ? Colors.white70 : const Color(0xFF4B5563), fontSize: bodySize)),
          SizedBox(height: _r(w, 0.04, 16, 20)),
          LayoutBuilder(builder: (context, cc) {
            final cw = cc.maxWidth;
            final chipPadH = _r(cw, 0.03, 10, 13);
            final chipPadV = _r(cw, 0.02, 7, 9);
            final chipFont = _r(cw, 0.03, 10, 11);
            final ic = _r(cw, 0.04, 13, 14);
            Widget chip(IconData icon, String label, Color col) => Container(padding: EdgeInsets.symmetric(horizontal: chipPadH, vertical: chipPadV), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: ic, color: col), SizedBox(width: _r(cw, 0.015, 4, 6)), Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: chipFont, color: isDark ? Colors.white : const Color(0xFF0B0E0F)))]));
            return Wrap(spacing: _r(cw, 0.02, 8, 10), runSpacing: _r(cw, 0.02, 8, 10), children: [chip(Icons.verified_rounded, 'FSSAI Licensed', const Color(0xFF00C805)), chip(Icons.eco_rounded, 'NPOP Certified', const Color(0xFF00C805)), chip(Icons.science_rounded, 'Lab Tested QR', const Color(0xFF7C3AED))]);
          }),
        ]),
      );
    });
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final isMobile = w < 860;
      final h = _r(w, 0.78, 220, 300);
      Widget stack = Stack(fit: StackFit.expand, children: [
        ClipRRect(borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28)), child: Image.asset('assets/img/organic-farm-hero.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/img/unit.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3F4F6))))),
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.26)]))),
        Positioned(left: _r(w, 0.03, 10, 14), bottom: _r(w, 0.03, 10, 14), child: Container(padding: EdgeInsets.symmetric(horizontal: _r(w, 0.03, 10, 13), vertical: _r(w, 0.025, 8, 10)), decoration: BoxDecoration(color: Colors.white.withOpacity(0.97), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: _r(w, 0.08, 30, 36), height: _r(w, 0.08, 30, 36), decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(9)), child: Icon(Icons.agriculture_rounded, color: Colors.white, size: _r(w, 0.04, 16, 18))), SizedBox(width: _r(w, 0.02, 8, 10)), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pure, Varanasi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: _r(w, 0.03, 11, 12), color: const Color(0xFF0B0E0F))), Text('Kachhawa Road • 221313', style: TextStyle(fontSize: _r(w, 0.027, 10, 11), color: const Color(0xFF6B7280)))])]))),
        Positioned(right: _r(w, 0.03, 10, 14), top: _r(w, 0.03, 10, 14), child: Container(padding: EdgeInsets.symmetric(horizontal: _r(w, 0.025, 8, 10), vertical: _r(w, 0.02, 6, 8)), decoration: BoxDecoration(color: Colors.white.withOpacity(0.97), borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star_rounded, size: _r(w, 0.035, 12, 14), color: const Color(0xFFFFB020)), SizedBox(width: _r(w, 0.01, 3, 4)), Text('4.8/5 • 10k+ families', style: TextStyle(fontWeight: FontWeight.w800, fontSize: _r(w, 0.027, 10, 11), color: const Color(0xFF0B0E0F)))]))),
      ]);
      if (isMobile) return SizedBox(height: h, child: stack);
      return SizedBox.expand(child: stack);
    });
  }
}

class _TrustBar extends StatelessWidget {
  const _TrustBar({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: _r(w, 0.03, 12, 16), vertical: _r(w, 0.025, 10, 12)),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
        child: Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: _r(w, 0.02, 6, 8), spacing: _r(w, 0.02, 8, 12), children: [
          Row(mainAxisSize: MainAxisSize.min, children: [Text('TRUSTED FOR PURITY', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF), fontSize: _r(w, 0.025, 9, 10))), SizedBox(width: _r(w, 0.02, 8, 10)), Container(height: _r(w, 0.04, 12, 16), width: 1, color: isDark ? const Color(0xFF2A2E32) : const Color(0xFFE5E7EB))]),
          ...[('Certified Organic', Icons.eco_outlined), ('FSSAI Licensed', Icons.verified_outlined), ('Lab Tested', Icons.science_outlined), ('500+ Farmers', Icons.agriculture_outlined), ('Pan-India 48h', Icons.local_shipping_outlined)].map((e) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(e.$2, size: _r(w, 0.04, 14, 16), color: isDark ? Colors.white70 : const Color(0xFF6B7280)), SizedBox(width: _r(w, 0.015, 4, 6)), Text(e.$1, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF374151), fontSize: _r(w, 0.03, 10.5, 12)))])),
        ]),
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.eyebrow, required this.title, required this.subtitle, required this.isDark});
  final String eyebrow, title, subtitle;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: EdgeInsets.symmetric(horizontal: _r(w, 0.025, 10, 12), vertical: _r(w, 0.012, 5, 6)), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2620) : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF2A3A2E) : const Color(0xFFD1FAE5))), child: Text(eyebrow.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: _r(w, 0.025, 9, 10), color: const Color(0xFF00A63E)))),
        SizedBox(height: _r(w, 0.02, 8, 10)),
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.6, fontSize: _r(w, 0.055, 18, 22), color: isDark ? Colors.white : const Color(0xFF0B0E0F), height: 1.1)),
        SizedBox(height: _r(w, 0.015, 6, 8)),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white60 : const Color(0xFF6B7280), height: 1.6, fontSize: _r(w, 0.035, 12.5, 14))),
      ]);
    });
  }
}

class _StoryAndMission extends StatelessWidget {
  const _StoryAndMission({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final isDesktop = w > 860;
      final cardPad = _r(w, 0.035, 16, 20);
      final gap = _r(w, 0.025, 10, 14);
      final textCard = Container(
        padding: EdgeInsets.all(cardPad),
        decoration: _cardDeco(isDark, w, radius: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Who we are', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0B0E0F), fontSize: _r(w, 0.04, 15, 17))),
          SizedBox(height: _r(w, 0.015, 6, 8)),
          Text('Hari Om Traders began with a simple idea: jaggery should taste like sugarcane, not chemicals. We source directly from farmers around Pure, Varanasi and across UP, pay fair prices, and keep the process fully transparent — from cane to cube in 48 hours.', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF6B7280), height: 1.65, fontSize: _r(w, 0.032, 12.5, 13.5))),
          SizedBox(height: _r(w, 0.03, 14, 18)),
          LayoutBuilder(builder: (context, cc) {
            final cw = cc.maxWidth;
            if (cw < 340) return Column(children: [_MiniMission(icon: Icons.flag_rounded, title: 'Mission', desc: 'Pure, unrefined jaggery for every family — minerals intact.', accent: const Color(0xFF00C805), isDark: isDark), SizedBox(height: gap), _MiniMission(icon: Icons.visibility_rounded, title: 'Vision', desc: 'Fair income for farmers & honest sweetness.', accent: const Color(0xFF2563EB), isDark: isDark)]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _MiniMission(icon: Icons.flag_rounded, title: 'Mission', desc: 'Pure, unrefined jaggery for every family — minerals intact.', accent: const Color(0xFF00C805), isDark: isDark)), SizedBox(width: gap), Expanded(child: _MiniMission(icon: Icons.visibility_rounded, title: 'Vision', desc: 'Fair income for farmers & honest sweetness.', accent: const Color(0xFF2563EB), isDark: isDark))]);
          }),
          SizedBox(height: _r(w, 0.025, 10, 12)),
          Wrap(spacing: _r(w, 0.015, 6, 8), runSpacing: _r(w, 0.015, 6, 8), children: [_Tag('15+ varieties', isDark), _Tag('Wood-pressed', isDark), _Tag('No sulphur', isDark), _Tag('Lab QR', isDark)]),
        ]),
      );
      final imgH = _r(w, 0.65, 240, 340);
      final imageStack = ClipRRect(borderRadius: BorderRadius.circular(_r(w, 0.035, 16, 20)), child: SizedBox(height: isDesktop ? imgH : _r(w, 0.7, 220, 300), child: Row(children: [Expanded(child: Image.asset('assets/img/organic-farm-left.jpg', fit: BoxFit.cover, height: double.infinity, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE5E7EB)))), SizedBox(width: gap), Expanded(child: Column(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/img/sugarcane.jpg', fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFDCFCE7))))), SizedBox(height: gap), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/img/jaggery-blocks.jpg', fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFFEF3C7)))))]))])));
      if (isDesktop) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: textCard), SizedBox(width: gap), Expanded(child: imageStack)]);
      return Column(children: [textCard, SizedBox(height: gap), imageStack]);
    });
  }
}

class _MiniMission extends StatelessWidget {
  const _MiniMission({required this.icon, required this.title, required this.desc, required this.accent, required this.isDark});
  final IconData icon; final String title, desc; final Color accent; final bool isDark;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final pad = _r(w, 0.045, 18, 20);
      final iconBox = _r(w, 0.11, 40, 48);
      return Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE8E8E8)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.14 : 0.07), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: iconBox, height: iconBox, alignment: Alignment.center, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: accent.withOpacity(0.24), blurRadius: 12, offset: const Offset(0, 6))]), child: Icon(icon, size: _r(w, 0.055, 18, 20), color: Colors.white)),
            const Spacer(),
            Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(100)), child: Text(title.toUpperCase(), style: TextStyle(color: accent, fontSize: _r(w, 0.022, 7.5, 8.5), fontWeight: FontWeight.w900, letterSpacing: 0.6))),
          ]),
          SizedBox(height: _r(w, 0.03, 12, 14)),
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: _r(w, 0.04, 13.5, 15), color: isDark ? Colors.white : const Color(0xFF0F172A), height: 1.15)),
          SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: _r(w, 0.032, 11.5, 12.5), height: 1.6, color: isDark ? Colors.white60 : const Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: _r(w, 0.035, 14, 16)),
          Align(alignment: Alignment.centerLeft, child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2429) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF2A3441) : const Color(0xFFE2E8F0))), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)), const SizedBox(width: 6), Text('Core Value', style: TextStyle(fontSize: _r(w, 0.028, 10, 11), fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF475569)))]))),
        ]),
      );
    });
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.isDark);
  final String label; final bool isDark;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final double w = c.maxWidth.isFinite ? c.maxWidth : 300.0;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: _r(w, 0.05, 10, 12), vertical: _r(w, 0.025, 6, 7)),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1F2429) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF2A2E32) : const Color(0xFFE5E7EB))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, size: _r(w, 0.06, 11, 12), color: const Color(0xFF00C805)), SizedBox(width: _r(w, 0.03, 4, 6)), Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: _r(w, 0.055, 10, 11), color: isDark ? Colors.white70 : const Color(0xFF374151)))]),
      );
    });
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final stats = [('15+', 'Varieties', 'Powder to chikki'), ('500+', 'Farmers', 'Eastern UP'), ('10k+', 'Families', '4.8★ rated'), ('5T', 'Per day', 'Small-batch')];
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final pad = _r(w, 0.015, 8, 10);
      return Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(color: const Color(0xFF0B0E0F), borderRadius: BorderRadius.circular(_r(w, 0.035, 16, 20)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8))]),
        child: LayoutBuilder(builder: (context, cc) {
          final cw = cc.maxWidth;
          final narrow = cw < 560;
          final tiny = cw < 340;
          if (narrow) {
            final aspect = tiny ? 1.32 : 1.62;
            return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: stats.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: aspect, crossAxisSpacing: _r(cw, 0.02, 8, 10), mainAxisSpacing: _r(cw, 0.02, 8, 10)), itemBuilder: (_, i) => _StatCell(data: stats[i]));
          }
          return Row(children: [for (int i = 0; i < stats.length; i++) ...[Expanded(child: _StatCell(data: stats[i])), if (i != stats.length - 1) Container(width: 1, height: _r(cw, 0.07, 36, 48), color: Colors.white.withOpacity(0.10))]]);
        }),
      );
    });
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.data});
  final (String, String, String) data;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: _r(w, 0.07, 12, 16), vertical: _r(w, 0.06, 10, 14)),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(data.$1, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _r(w, 0.16, 18, 22), letterSpacing: -0.8)),
          SizedBox(height: 2),
          Text(data.$2, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: _r(w, 0.08, 11, 12))),
          Text(data.$3, style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: _r(w, 0.07, 10, 11))),
        ])),
      );
    });
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [_Step('2018', 'Started at Pure', '1 farmer, 1 kadhai. Sold at local haat with a promise: no sulphur, ever.', Icons.spa_rounded, const Color(0xFF00C805)), _Step('2020', '100 farmers', 'Built wood-pressed unit. First FSSAI license, first lab test with QR.', Icons.agriculture_rounded, const Color(0xFF2563EB)), _Step('2022', 'Pan-India reach', '15+ varieties — powder, kakvi, chikki, syrups. 5T/day.', Icons.local_shipping_rounded, const Color(0xFFEA580C)), _Step('Today', '10k+ families', '500+ farmers, NPOP organic, every batch tested.', Icons.verified_rounded, const Color(0xFF7C3AED))];
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Container(padding: EdgeInsets.all(_r(w, 0.035, 16, 20)), decoration: _cardDeco(isDark, w), child: LayoutBuilder(builder: (context, cc) {
        final cw = cc.maxWidth;
        final isDesktop = cw > 760;
        if (isDesktop) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (int i = 0; i < steps.length; i++) ...[Expanded(child: _StepCard(step: steps[i], isDark: isDark, theme: theme)), if (i != steps.length - 1) _HLine(from: steps[i].accent, to: steps[i + 1].accent)]]);
        return Column(children: [for (int i = 0; i < steps.length; i++) ...[_StepCard(step: steps[i], isDark: isDark, theme: theme, horizontal: true), if (i != steps.length - 1) _VLine(from: steps[i].accent, to: steps[i + 1].accent)]]);
      }));
    });
  }
}

class _Step {
  const _Step(this.year, this.title, this.desc, this.icon, this.accent);
  final String year, title, desc; final IconData icon; final Color accent;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.isDark, required this.theme, this.horizontal = false});
  final _Step step; final bool isDark; final ThemeData theme; final bool horizontal;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      // Convert to personnel-like card when horizontal (mobile) - full card style
      if (horizontal) {
        return Container(
          padding: EdgeInsets.all(_r(w, 0.045, 16, 18)),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE8E8E8)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.08 : 0.05), blurRadius: 14, offset: const Offset(0, 6))]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: _r(w, 0.11, 40, 44), height: _r(w, 0.11, 40, 44), alignment: Alignment.center, decoration: BoxDecoration(color: step.accent, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: step.accent.withOpacity(0.24), blurRadius: 12, offset: const Offset(0, 6))]), child: Icon(step.icon, color: Colors.white, size: _r(w, 0.055, 18, 20))),
            SizedBox(width: _r(w, 0.03, 10, 12)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(step.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: _r(w, 0.04, 12.5, 14), color: isDark ? Colors.white : const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis)), SizedBox(width: 8), Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: step.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(100)), child: Text(step.year, style: TextStyle(color: step.accent, fontSize: _r(w, 0.022, 7.5, 8.5), fontWeight: FontWeight.w900)))]),
              SizedBox(height: 4),
              Text(step.desc, style: TextStyle(fontSize: _r(w, 0.03, 11, 12), height: 1.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        );
      }
      // Desktop - vertical centered card like before but in card container
      return Container(
        padding: EdgeInsets.all(_r(w, 0.04, 14, 16)),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(width: _r(w, 0.16, 40, 44), height: _r(w, 0.16, 40, 44), alignment: Alignment.center, decoration: BoxDecoration(color: step.accent, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: step.accent.withOpacity(0.24), blurRadius: 12, offset: const Offset(0, 6))]), child: Icon(step.icon, color: Colors.white, size: _r(w, 0.07, 18, 20))),
          SizedBox(height: _r(w, 0.025, 8, 10)),
          Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: step.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(100)), child: Text(step.year, style: TextStyle(color: step.accent, fontSize: _r(w, 0.022, 7.5, 8.5), fontWeight: FontWeight.w900))),
          SizedBox(height: _r(w, 0.02, 6, 8)),
          Text(step.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: _r(w, 0.04, 12, 13), color: isDark ? Colors.white : const Color(0xFF0F172A)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 4),
          Text(step.desc, style: TextStyle(fontSize: _r(w, 0.03, 11, 12), height: 1.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      );
    });
  }
}

class _HLine extends StatelessWidget {
  const _HLine({required this.from, required this.to});
  final Color from, to;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 22), child: Container(width: 24, height: 2, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(gradient: LinearGradient(colors: [from.withOpacity(0.5), to.withOpacity(0.5)]), borderRadius: BorderRadius.circular(100))));
}

class _VLine extends StatelessWidget {
  const _VLine({required this.from, required this.to});
  final Color from, to;
  @override
  Widget build(BuildContext context) => Container(width: 2, height: 16, margin: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [from.withOpacity(0.5), to.withOpacity(0.5)]), borderRadius: BorderRadius.circular(100)));
}

class _ValuesBento extends StatelessWidget {
  const _ValuesBento({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final gap = _r(w, 0.02, 10, 14);
      final values = [_Value('Farmer First', 'Fair price, timely payment, organic training. We grow together or not at all.', Icons.handshake_rounded, const Color(0xFF00C805)), _Value('Purity Over Profit', 'No sulphur, no bleach, no shortcuts. Iron kadhai, wood fire, patience.', Icons.health_and_safety_rounded, const Color(0xFFEA580C)), _Value('Radical Transparency', 'Batch QR • lab report • farm visits. Check anything, anytime.', Icons.visibility_rounded, const Color(0xFF2563EB))];
      final cross = w > 800 ? 3 : 1;
      if (cross == 1) return Column(children: [for (final v in values) Padding(padding: EdgeInsets.only(bottom: gap), child: _ValueCard(v: v, isDark: isDark))]);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final v in values) Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: gap / 2), child: _ValueCard(v: v, isDark: isDark)))]);
    });
  }
}

class _Value { const _Value(this.title, this.desc, this.icon, this.accent); final String title, desc; final IconData icon; final Color accent; }

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.v, required this.isDark});
  final _Value v; final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final pad = _r(w, 0.045, 18, 20);
      return Container(
        padding: EdgeInsets.all(pad),
        decoration: _cardDeco(isDark, w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: _r(w, 0.11, 40, 48), height: _r(w, 0.11, 40, 48), alignment: Alignment.center, decoration: BoxDecoration(color: v.accent, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: v.accent.withOpacity(0.24), blurRadius: 12, offset: const Offset(0, 6))]), child: Icon(v.icon, color: Colors.white, size: _r(w, 0.055, 18, 20))),
            const Spacer(),
            Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: v.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(100)), child: Text('VALUE', style: TextStyle(color: v.accent, fontSize: _r(w, 0.022, 7.5, 8.5), fontWeight: FontWeight.w900, letterSpacing: 0.6))),
          ]),
          SizedBox(height: _r(w, 0.03, 12, 14)),
          Text(v.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: _r(w, 0.04, 13.5, 15))),
          SizedBox(height: 4),
          Text(v.desc, style: theme.textTheme.bodySmall?.copyWith(height: 1.6, color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: _r(w, 0.032, 11.5, 12.5), fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: _r(w, 0.035, 14, 16)),
          Align(alignment: Alignment.centerLeft, child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2429) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF2A3441) : const Color(0xFFE2E8F0))), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: v.accent, shape: BoxShape.circle)), const SizedBox(width: 6), Text('Core Principle', style: TextStyle(fontSize: _r(w, 0.028, 10, 11), fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF475569)))]))),
        ]),
      );
    });
  }
}

// ───────────────── TEAM ─────────────────
class _TeamSection extends StatelessWidget {
  const _TeamSection({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final people = [_Person('Rahul Kumar Singh', 'Proprietor & Founder', 'Vision, farmer partnerships & growth. Building Hari Om since 2018 in Pure, Varanasi.', Icons.person_rounded, const Color(0xFF0B0E0F), true, '9818 247 879'), _Person('Janaki Devi', 'Manager', 'Operations, quality checks & customer happiness. Bulk orders & daily management.', Icons.manage_accounts_rounded, const Color(0xFF15803D), true, '9936 447 879'), _Person('Amit Kumar', 'Production Head', 'Leads 5T/day wood-pressed unit. Chulha, iron kadhai & hygiene.', Icons.precision_manufacturing_rounded, const Color(0xFFEA580C), false, 'Production'), _Person('Priya Sharma', 'Quality & Lab In-charge', 'Every batch tested — COA QR, sulphur & purity checks.', Icons.science_rounded, const Color(0xFF7C3AED), false, 'Quality')];
      final cross = w > 600 ? 2 : 1;
      double aspect;
      if (cross == 1) aspect = w < 340 ? 0.92 : w < 380 ? 1.02 : w < 420 ? 1.18 : 1.38;
      else aspect = w < 800 ? 1.32 : 1.75;
      final gap = _r(w, 0.025, 10, 14);
      return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: people.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross, crossAxisSpacing: gap, mainAxisSpacing: gap, childAspectRatio: aspect), itemBuilder: (_, i) => _PersonCard(p: people[i], isDark: isDark));
    });
  }
}

class _Person { const _Person(this.name, this.role, this.bio, this.icon, this.accent, this.isHead, this.meta); final String name, role, bio; final IconData icon; final Color accent; final bool isHead; final String meta; }

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.p, required this.isDark});
  final _Person p; final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final rOuter = _r(w, 0.055, 16, 20);
      final rInner = (rOuter - 3).clamp(10, 16).toDouble();
      final pad = _r(w, 0.04, 10, 16);
      final avatar = _r(w, 0.22, 52, 68);
      final ring = _r(w, 0.02, 4, 6);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(rOuter),
          border: Border.all(color: p.accent, width: 2.8),
          boxShadow: [
            BoxShadow(color: p.accent.withOpacity(isDark ? 0.22 : 0.14), blurRadius: 14, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.28 : 0.09), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(rInner),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [const Color(0xFF1E2620), const Color(0xFF141C1A), const Color(0xFF19201E)] : [const Color(0xFFFDFFFE), const Color(0xFFF4F7F9), const Color(0xFFEAF0F5)],
            ),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.85), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned(
              left: -12,
              top: 18,
              child: Opacity(opacity: isDark ? 0.04 : 0.06, child: Icon(p.icon, size: _r(w, 0.50, 85, 110), color: p.accent)),
            ),
            Positioned(
              right: -10,
              bottom: 22,
              child: Opacity(opacity: isDark ? 0.03 : 0.04, child: Icon(Icons.hdr_strong_rounded, size: _r(w, 0.40, 65, 85), color: p.accent)),
            ),
            Positioned(
              top: 0,
              left: 12,
              right: 12,
              child: Container(
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(isDark ? 0.18 : 0.75), Colors.white.withOpacity(0)]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad - 2, pad, pad - 2),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF122016) : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isDark ? const Color(0xFF1E3A28) : const Color(0xFFE2E8F0)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (p.isHead)
                          Container(width: 13, height: 13, decoration: const BoxDecoration(color: Color(0xFF00C805), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 9, color: Colors.white))
                        else
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: p.accent.withOpacity(0.35), blurRadius: 6)])),
                        const SizedBox(width: 4),
                        Text(p.isHead ? 'LEAD' : 'TEAM', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: p.isHead ? const Color(0xFF15803D) : p.accent)),
                      ]),
                    ),
                  ),
                ),
                SizedBox(height: _r(w, 0.02, 4, 8)),
                Container(
                  width: avatar + ring * 2,
                  height: avatar + ring * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF2A3441), const Color(0xFF1E2429)] : [Colors.white, const Color(0xFFE6ECF3)]),
                    border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.95), width: 1.4),
                    boxShadow: [
                      BoxShadow(color: Colors.white.withOpacity(isDark ? 0.06 : 0.9), blurRadius: 0, offset: const Offset(-1.5, -1.5)),
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.32 : 0.13), blurRadius: 14, offset: const Offset(0, 7)),
                      BoxShadow(color: p.accent.withOpacity(isDark ? 0.18 : 0.13), blurRadius: 18, offset: const Offset(0, 0)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: avatar,
                    height: avatar,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.accent,
                      border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
                      boxShadow: [BoxShadow(color: p.accent.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    alignment: Alignment.center,
                    child: Icon(p.icon, color: Colors.white, size: _r(w, 0.10, 24, 30)),
                  ),
                ),
                SizedBox(height: _r(w, 0.035, 8, 12)),
                Text(p.name, textAlign: TextAlign.center, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: _r(w, 0.042, 12, 16), color: isDark ? Colors.white : const Color(0xFF0B1220), height: 1.15), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: _r(w, 0.012, 3, 5)),
                Text(p.role, textAlign: TextAlign.center, style: TextStyle(fontSize: _r(w, 0.036, 9.5, 12), fontWeight: FontWeight.w700, color: p.accent, height: 1.25), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: _r(w, 0.02, 6, 8)),
                Text(p.bio, textAlign: TextAlign.center, style: TextStyle(fontSize: _r(w, 0.032, 9.5, 11), height: 1.5, color: isDark ? Colors.white60 : const Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                SizedBox(height: _r(w, 0.03, 8, 12)),
                Row(children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2620) : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isDark ? const Color(0xFF2A3A30) : const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: p.accent.withOpacity(0.35), blurRadius: 6)])),
                          const SizedBox(width: 5),
                          Text(p.isHead ? 'Lead' : 'Core', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: isDark ? [const Color(0xFF24302A), const Color(0xFF1A2620)] : [Colors.white, const Color(0xFFF1F5F9)]),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isDark ? const Color(0xFF2F3D36) : const Color(0xFFCBD5E1)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF2A3441) : const Color(0xFFE2E8F0), shape: BoxShape.circle, border: Border.all(color: isDark ? const Color(0xFF3A4A5A) : Colors.white, width: 1)),
                            child: Icon(Icons.phone_rounded, size: 8, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                          const SizedBox(width: 4),
                          Text(p.meta, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      );
    });
  }
}

// ───────────────── CERTIFICATIONS ─────────────────
class _CertSection extends StatelessWidget {
  const _CertSection({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final gap = _r(w, 0.025, 10, 14);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CertHeaderRow(isDark: isDark, icon: Icons.business_rounded, label: 'Organisation', hint: 'Licenses & registrations'),
        SizedBox(height: _r(w, 0.02, 8, 10)),
        LayoutBuilder(builder: (context, cc) {
          final cw = cc.maxWidth;
          final cross = cw > 700 ? 3 : 2;
          final aspect = cross == 3 ? 1.32 : (cw < 340 ? 0.62 : cw < 380 ? 0.70 : cw < 500 ? 0.88 : 1.12);
          const org = [_Cert('FSSAI Licensed', 'Lic. No: 2272XXXXXXX', 'Food Safety & Standards', Icons.verified_rounded, Color(0xFF00C805)), _Cert('India Organic', 'NPOP • APEDA • Jaivik Bharat', 'Cert No: ORG-XXXX', Icons.eco_rounded, Color(0xFF15803D)), _Cert('MSME Udyam', 'Udyam-UP-XX-XXXXXXX', 'Govt. of India', Icons.business_rounded, Color(0xFF2563EB)), _Cert('GST Registered', 'GSTIN: 09XXXXX', 'Tax compliant', Icons.receipt_long_rounded, Color(0xFF0B0E0F)), _Cert('ISO 22000:2018', 'Food Safety Management', 'Process certified', Icons.workspace_premium_rounded, Color(0xFF7C3AED)), _Cert('GMP & HACCP', 'Hygienic Production', 'Compliant unit', Icons.health_and_safety_rounded, Color(0xFFEA580C))];
          return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: org.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross, crossAxisSpacing: gap, mainAxisSpacing: gap, childAspectRatio: aspect), itemBuilder: (_, i) => _CertCard(c: org[i], isDark: isDark));
        }),
        SizedBox(height: _r(w, 0.03, 14, 18)),
        _CertHeaderRow(isDark: isDark, icon: Icons.spa_rounded, label: 'Product Purity', hint: 'Every batch promise'),
        SizedBox(height: _r(w, 0.02, 8, 10)),
        LayoutBuilder(builder: (context, cc) {
          final cw = cc.maxWidth;
          final cross = cw > 700 ? 3 : 2;
          final aspect = cross == 3 ? 1.32 : (cw < 340 ? 0.62 : cw < 380 ? 0.70 : cw < 500 ? 0.88 : 1.12);
          const prod = [_Cert('Lab Tested', 'COA with QR • Every batch', 'Sulphur & purity check', Icons.science_rounded, Color(0xFF7C3AED)), _Cert('Sulphur Free', 'No chemicals • No bleach', 'Pure cane only', Icons.block_rounded, Color(0xFFDC2626)), _Cert('Wood-Pressed', 'Iron kadhai • Wood chulha', 'Traditional 4-hr boil', Icons.local_fire_department_rounded, Color(0xFFEA580C)), _Cert('100% Organic', 'Zero pesticide • Neem', 'Cow-dung manure', Icons.spa_rounded, Color(0xFF00C805)), _Cert('Iron Rich', '~12 mg / 100g • Minerals', 'Unrefined goodness', Icons.favorite_rounded, Color(0xFFDC2626)), _Cert('Food-Grade Pack', 'Pouch & jar • Hygienic', 'Pan-India 48h', Icons.inventory_2_rounded, Color(0xFF2563EB))];
          return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: prod.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross, crossAxisSpacing: gap, mainAxisSpacing: gap, childAspectRatio: aspect), itemBuilder: (_, i) => _CertCard(c: prod[i], isDark: isDark));
        }),
        SizedBox(height: _r(w, 0.02, 10, 12)),
        Container(padding: EdgeInsets.symmetric(horizontal: _r(w, 0.03, 12, 14), vertical: _r(w, 0.02, 9, 11)), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2620) : const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF2A3A2E) : const Color(0xFFDCFCE7))), child: Row(children: [Icon(Icons.info_outline_rounded, size: _r(w, 0.035, 12, 14), color: const Color(0xFF15803D)), SizedBox(width: _r(w, 0.02, 7, 8)), Expanded(child: Text('Numbers are placeholders — replace with actual FSSAI / NPOP / GST numbers. Add scans to assets/img/certificates/.', style: theme.textTheme.labelSmall?.copyWith(fontSize: _r(w, 0.028, 10, 11), height: 1.5, color: isDark ? Colors.white70 : const Color(0xFF14532D))))])),
      ]);
    });
  }
}

class _CertHeaderRow extends StatelessWidget {
  const _CertHeaderRow({required this.isDark, required this.icon, required this.label, required this.hint});
  final bool isDark; final IconData icon; final String label, hint;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Row(children: [
        Container(padding: EdgeInsets.symmetric(horizontal: _r(w, 0.035, 10, 12), vertical: _r(w, 0.018, 6, 7)), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(100), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: const Color(0xFF00C805)), SizedBox(width: 6), Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: _r(w, 0.032, 10, 11), letterSpacing: 0.3))])),
        SizedBox(width: _r(w, 0.02, 8, 10)),
        Expanded(child: Text(hint, style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF9CA3AF), fontSize: _r(w, 0.03, 10.5, 12)), overflow: TextOverflow.ellipsis)),
      ]);
    });
  }
}

class _Cert { const _Cert(this.title, this.subtitle, this.meta, this.icon, this.accent); final String title, subtitle, meta; final IconData icon; final Color accent; }

class _CertCard extends StatelessWidget {
  const _CertCard({required this.c, required this.isDark});
  final _Cert c; final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, cc) {
      final w = cc.maxWidth;
      final rOuter = _r(w, 0.055, 14, 20);
      final rInner = (rOuter - 3).clamp(10, 16).toDouble();
      final pad = _r(w, 0.04, 8, 16);
      final iconBox = _r(w, 0.20, 44, 72);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(rOuter),
          border: Border.all(color: c.accent, width: 2.8),
          boxShadow: [
            BoxShadow(color: c.accent.withOpacity(isDark ? 0.22 : 0.14), blurRadius: 14, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.28 : 0.09), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(rInner),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E2620), const Color(0xFF141C1A), const Color(0xFF19201E)]
                  : [const Color(0xFFFDFFFE), const Color(0xFFF4F7F9), const Color(0xFFEAF0F5)],
            ),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.85), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            // faint watermark pattern
            Positioned(
              left: -10,
              top: 24,
              child: Opacity(
                opacity: isDark ? 0.04 : 0.06,
                child: Icon(c.icon, size: _r(w, 0.55, 90, 110), color: c.accent),
              ),
            ),
            Positioned(
              right: -14,
              bottom: 28,
              child: Opacity(
                opacity: isDark ? 0.03 : 0.04,
                child: Icon(Icons.hdr_strong_rounded, size: _r(w, 0.45, 70, 88), color: c.accent),
              ),
            ),
            // glossy highlight streak top
            Positioned(
              top: 0,
              left: 12,
              right: 12,
              child: Container(
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(isDark ? 0.18 : 0.75), Colors.white.withOpacity(0)]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad - 2, pad, pad - 2),
              child: Column(children: [
                // VERIFIED pill top-right
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF122016) : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isDark ? const Color(0xFF1E3A28) : const Color(0xFFE2E8F0)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 13,
                          height: 13,
                          decoration: const BoxDecoration(color: Color(0xFF00C805), shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 9, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        const Text('VERIFIED', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Color(0xFF15803D))),
                      ]),
                    ),
                  ),
                ),
                SizedBox(height: _r(w, 0.02, 4, 8)),
                // 3D icon box centered — scales with available width
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_r(w, 0.045, 12, 16)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark ? [const Color(0xFF2A3441), const Color(0xFF1E2429)] : [Colors.white, const Color(0xFFE6ECF3)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.95), width: 1.4),
                    boxShadow: [
                      BoxShadow(color: Colors.white.withOpacity(isDark ? 0.06 : 0.9), blurRadius: 0, offset: const Offset(-1.5, -1.5)),
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.32 : 0.13), blurRadius: 14, offset: const Offset(0, 7)),
                      BoxShadow(color: c.accent.withOpacity(isDark ? 0.18 : 0.13), blurRadius: 18, offset: const Offset(0, 0)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: iconBox - 10,
                    height: iconBox - 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_r(w, 0.035, 10, 13)),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.accent.withOpacity(0.14), c.accent.withOpacity(0.04)]),
                    ),
                    child: Icon(c.icon, size: _r(w, 0.11, 22, 34), color: c.accent),
                  ),
                ),
                SizedBox(height: _r(w, 0.035, 8, 14)),
                Text(c.title, textAlign: TextAlign.center, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: _r(w, 0.042, 11.5, 16), color: isDark ? Colors.white : const Color(0xFF0B1220), height: 1.15), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: _r(w, 0.012, 3, 5)),
                Text(c.subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: _r(w, 0.036, 9.5, 12), fontWeight: FontWeight.w700, color: c.accent, height: 1.25), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: _r(w, 0.008, 1, 3)),
                Text(c.meta, textAlign: TextAlign.center, style: TextStyle(fontSize: _r(w, 0.032, 9, 11), color: isDark ? Colors.white60 : const Color(0xFF6B7280), height: 1.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),
                SizedBox(height: _r(w, 0.03, 8, 14)),
                // bottom two pills — Certified left, Verified right
                Row(children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2620) : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isDark ? const Color(0xFF2A3A30) : const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.accent.withOpacity(0.35), blurRadius: 6)])),
                          const SizedBox(width: 5),
                          Text('Certified', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: isDark ? [const Color(0xFF24302A), const Color(0xFF1A2620)] : [Colors.white, const Color(0xFFF1F5F9)]),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isDark ? const Color(0xFF2F3D36) : const Color(0xFFCBD5E1)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF2A3441) : const Color(0xFFE2E8F0), shape: BoxShape.circle, border: Border.all(color: isDark ? const Color(0xFF3A4A5A) : Colors.white, width: 1)),
                            child: Icon(Icons.check_rounded, size: 8, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                          const SizedBox(width: 4),
                          Text('Verified', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      );
    });
  }
}

class _FarmCTA extends StatelessWidget {
  const _FarmCTA({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final isDesktop = w > 700;
      final pad = _r(w, 0.04, 18, 24);
      return Container(
        decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B0E0F), Color(0xFF1C2A1E)]), borderRadius: BorderRadius.circular(_r(w, 0.035, 16, 20))),
        clipBehavior: Clip.antiAlias,
        child: isDesktop
            ? Row(children: [
                Expanded(flex: 12, child: Padding(padding: EdgeInsets.all(pad), child: _FarmCopy(theme: theme, w: w))),
                Expanded(flex: 10, child: SizedBox(height: 280, child: Image.asset('assets/img/organic-farm-right.jpg', fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Image.asset('assets/img/unit.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1C2A1E)))))),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Padding(padding: EdgeInsets.all(pad), child: _FarmCopy(theme: theme, w: w)), SizedBox(height: _r(w, 0.45, 180, 220), child: Image.asset('assets/img/organic-farm-right.jpg', fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Image.asset('assets/img/unit.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1C2A1E)))))]) ,
      );
    });
  }
}

class _FarmCopy extends StatelessWidget {
  const _FarmCopy({required this.theme, required this.w});
  final ThemeData theme; final double w;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Align(alignment: Alignment.centerLeft, child: FittedBox(fit: BoxFit.scaleDown, child: Container(padding: EdgeInsets.symmetric(horizontal: _r(w, 0.025, 10, 12), vertical: _r(w, 0.015, 5, 6)), decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withOpacity(0.14))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.spa, size: 11, color: const Color(0xFF22C55E)), SizedBox(width: 5), Text("LET'S GROW TOGETHER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.1, fontSize: _r(w, 0.022, 9, 10)))])))),
      SizedBox(height: _r(w, 0.025, 12, 14)),
      Text("Come, see how\njaggery is made.", style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.05, fontSize: _r(w, 0.05, 20, 24))),
      SizedBox(height: _r(w, 0.02, 8, 10)),
      Text('Factory visits welcome • Mon–Sat 8am–6pm • Pure, Kachhawa Road, Varanasi 221313', style: TextStyle(color: Colors.white.withOpacity(0.72), height: 1.6, fontSize: _r(w, 0.03, 12, 13))),
      SizedBox(height: _r(w, 0.03, 14, 16)),
      Wrap(spacing: _r(w, 0.02, 8, 10), runSpacing: _r(w, 0.02, 8, 10), children: [
        Container(padding: EdgeInsets.symmetric(horizontal: _r(w, 0.03, 12, 14), vertical: _r(w, 0.02, 9, 11)), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.location_on_rounded, size: 15, color: const Color(0xFF0B0E0F)), const SizedBox(width: 6), Flexible(child: Text(CompanyInfo.shortAddress, style: TextStyle(fontWeight: FontWeight.w800, fontSize: _r(w, 0.028, 11, 12), color: const Color(0xFF0B0E0F)), overflow: TextOverflow.ellipsis)) ])),
        FittedBox(fit: BoxFit.scaleDown, child: Container(padding: EdgeInsets.symmetric(horizontal: _r(w, 0.03, 12, 14), vertical: _r(w, 0.02, 9, 11)), decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withOpacity(0.18))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.call_rounded, size: 15, color: Colors.white), const SizedBox(width: 6), Text(CompanyInfo.phone1, style: TextStyle(fontWeight: FontWeight.w800, fontSize: _r(w, 0.028, 11, 12), color: Colors.white))]))),
      ]),
    ]);
  }
}

class _ContactSnippet extends StatelessWidget {
  const _ContactSnippet({required this.isDark, required this.theme});
  final bool isDark; final ThemeData theme;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final pad = _r(w, 0.035, 16, 18);
      final gap = _r(w, 0.02, 10, 12);
      return Container(
        padding: EdgeInsets.all(pad),
        decoration: _cardDeco(isDark, w),
        child: Column(children: [
          _InfoRow(icon: Icons.schedule_rounded, title: 'Open hours', subtitle: 'Mon–Sat 8am–6pm • Sun closed', isDark: isDark),
          SizedBox(height: gap),
          Divider(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB), height: 1),
          SizedBox(height: gap),
          _InfoRow(icon: Icons.bolt_rounded, title: 'Avg response', subtitle: '2–3 hours on WhatsApp • Replies within 12h', isDark: isDark),
          SizedBox(height: gap),
          Divider(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB), height: 1),
          SizedBox(height: gap),
          _InfoRow(icon: Icons.verified_rounded, title: 'Trusted', subtitle: '10k+ families • FSSAI • Lab tested • NPOP', isDark: isDark),
        ]),
      );
    });
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.subtitle, required this.isDark});
  final IconData icon; final String title, subtitle; final bool isDark;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final box = _r(w, 0.08, 34, 38);
      return Row(children: [
        Container(width: box, height: box, alignment: Alignment.center, decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(11), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))), child: Icon(icon, size: 17, color: isDark ? Colors.white70 : const Color(0xFF374151))),
        SizedBox(width: _r(w, 0.03, 12, 14)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: _r(w, 0.032, 12, 13), color: isDark ? Colors.white : const Color(0xFF0B0E0F))), Text(subtitle, style: TextStyle(fontSize: _r(w, 0.028, 11, 12), color: isDark ? Colors.white60 : const Color(0xFF6B7280)), maxLines: 2, overflow: TextOverflow.ellipsis)])),
      ]);
    });
  }
}
