import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/scroll_manager.dart';

// ─── RESPONSIVE HELPER ───
// All sizes / positions are derived from screen width/height so UI scales
// proportionally on mobile, tablet and desktop.
class _R {
  static double w(BuildContext c) => MediaQuery.sizeOf(c).width;
  static double h(BuildContext c) => MediaQuery.sizeOf(c).height;

  static bool isSmallPhone(BuildContext c) => w(c) < 360;
  static bool isPhone(BuildContext c) => w(c) < 600;
  static bool isTablet(BuildContext c) => w(c) >= 600 && w(c) < 1100;
  static bool isDesktop(BuildContext c) => w(c) >= 1100;
  static bool isWide(BuildContext c) => w(c) >= 900;

  // horizontal page padding — 4% of width, clamped
  static double hPad(BuildContext c) {
    final width = w(c);
    if (width >= 1100) return 32;
    if (width >= 700) return 24;
    if (width >= 400) return 20;
    return 16;
  }

  // hero height — relative to screen height, clamped per breakpoint
  static double heroHeight(BuildContext c) {
    final height = h(c);
    final width = w(c);
    if (width >= 1100) return (height * 0.62).clamp(420.0, 560.0);
    if (width >= 700) return (height * 0.55).clamp(360.0, 480.0);
    return (height * 0.52).clamp(320.0, 400.0);
  }

  static double galleryHeight(BuildContext c) {
    final width = w(c);
    if (width >= 1100) return 340;
    if (width >= 700) return 280;
    return (width * 0.60).clamp(185.0, 250.0);
  }

  static double font(BuildContext c, double base) {
    final width = w(c);
    if (width >= 1100) return base * 1.14;
    if (width >= 700) return base * 1.06;
    if (width < 360) return base * 0.90;
    return base;
  }

  static double radius(BuildContext c, double base) {
    final width = w(c);
    if (width < 360) return base * 0.85;
    return base;
  }
}

class FeatureDetailPage extends StatefulWidget {
  const FeatureDetailPage({super.key, required this.slug});
  final String slug;
  @override
  State<FeatureDetailPage> createState() => _FeatureDetailPageState();
}

class _FeatureDetailPageState extends State<FeatureDetailPage> with TickerProviderStateMixin {
  late AnimationController _entrance;
  late AnimationController _heroZoom;
  late AnimationController _stickyCtrl;
  late ScrollController _scrollCtrl;
  double _scrollProgress = 0;
  bool _showSticky = false;
  bool _showFab = false;

  static const Map<String, Map<String, dynamic>> _features = {
    '100-organic': {
      'icon': Icons.eco_rounded,
      'accent': Color(0xFF00C805),
      'badge': 'NPOP certified',
      'title': '100% Organic',
      'subtitle': 'Certified cane, zero pesticides. Grown with cow-dung manure & neem.',
      'heroUrl': 'https://images.unsplash.com/photo-1586771107445-b3dba3460b77?w=1200&q=80',
      'stats': [
        {'value': '0', 'label': 'Pesticides', 'icon': Icons.block},
        {'value': '100%', 'label': 'Organic', 'icon': Icons.eco},
        {'value': 'NPOP', 'label': 'Certified', 'icon': Icons.verified},
      ],
      'galleryUrls': [
        'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=600&q=80',
        'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=600&q=80',
        'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=600&q=80',
      ],
      'process': [
        {'step': '01', 'title': 'Organic Soil Prep', 'desc': 'Cow-dung manure & neem cake enrich the soil naturally'},
        {'step': '02', 'title': 'Zero Chemicals', 'desc': 'No synthetic pesticides or fertilizers at any stage'},
        {'step': '03', 'title': 'NPOP Audit', 'desc': 'Annual third-party certification audit & soil testing'},
        {'step': '04', 'title': 'Farm to Pack', 'desc': 'Traceable from certified farm to your kitchen'},
      ],
      'sections': [
        {
          'heading': 'What Makes It Organic',
          'body': 'Every gram of our jaggery comes from certified organic sugarcane farms in Eastern Uttar Pradesh. We use zero synthetic pesticides, zero chemical fertilizers, and rely entirely on traditional cow-dung manure and neem-based pest control.\n\nOur farms hold NPOP (National Programme for Organic Production) certification, which is recognized by the USDA, EU, and JAS — meaning our jaggery meets the strictest global organic standards.',
          'imageUrl': 'https://images.unsplash.com/photo-1500651230702-0e2d8a49d4ad?w=800&q=80',
        },
        {
          'heading': 'The NPOP Certification',
          'body': 'NPOP certification requires rigorous annual audits of soil health, water quality, input traceability, and supply-chain integrity. Every batch is tracked from cane-cutting to final packaging with a unique lot number you can trace back to the exact farm.',
          'imageUrl': 'https://images.unsplash.com/photo-1589923188651-268a9765e432?w=800&q=80',
        },
        {
          'heading': 'Why It Tastes Different',
          'body': 'Organic sugarcane develops deeper mineral complexity because the soil microbiome is alive and diverse. The result is a richer, more caramel-forward flavour with natural iron and calcium that you simply cannot get from chemically-grown cane.',
          'imageUrl': 'https://images.unsplash.com/photo-1558642452-9d2a7deb7f62?w=800&q=80',
        },
      ],
    },
    'wood-pressed': {
      'icon': Icons.local_fire_department_rounded,
      'accent': Color(0xFFEA580C),
      'badge': 'Traditional chulha',
      'title': 'Wood-Pressed',
      'subtitle': 'Juice slow-pressed, boiled in iron kadhai over wood fire — no sulphur.',
      'heroUrl': 'https://images.unsplash.com/photo-1473973916745-60839aebf0bd?w=1200&q=80',
      'stats': [
        {'value': '4-5h', 'label': 'Slow Boil', 'icon': Icons.schedule},
        {'value': '0', 'label': 'Sulphur', 'icon': Icons.block},
        {'value': '100%', 'label': 'Iron Kadhai', 'icon': Icons.local_fire_department},
      ],
      'galleryUrls': [
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80',
        'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600&q=80',
        'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=600&q=80',
      ],
      'process': [
        {'step': '01', 'title': 'Fresh Cane Press', 'desc': 'Sugarcane crushed within hours of harvest'},
        {'step': '02', 'title': 'Iron Kadhai Boil', 'desc': 'Slow boiled 4-5 hours over wood fire in iron vessels'},
        {'step': '03', 'title': 'Natural Setting', 'desc': 'Poured into moulds, set naturally without chemicals'},
        {'step': '04', 'title': 'Hand-Cut Pieces', 'desc': 'Cut, sorted, and packed by hand'},
      ],
      'sections': [
        {
          'heading': 'The Wood-Fire Method',
          'body': 'Our jaggery is made the way it has been for centuries — fresh sugarcane juice is slow-pressed using a traditional gurghad (wood-press) and then boiled in large iron kadhai vessels over a controlled wood fire.\n\nThis slow, low-temperature process preserves the natural molasses, minerals, and caramel notes that high-pressure industrial processing destroys.',
          'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&q=80',
        },
        {
          'heading': 'Iron Kadhai Advantage',
          'body': 'Boiling in iron kadhai naturally infuses the jaggery with bioavailable iron — the same reason traditional Indian cooking uses iron cookware. This is not added; it happens naturally during the 4-5 hour boiling process.\n\nNo aluminium, no non-stick, no stainless steel — just iron and fire.',
          'imageUrl': 'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=800&q=80',
        },
        {
          'heading': 'Zero Sulphur Promise',
          'body': 'Most commercial jaggery is treated with sulphur dioxide to lighten colour and extend shelf life. We never do this. Our jaggery retains its natural golden-amber colour because it has nothing to hide.',
          'imageUrl': 'https://images.unsplash.com/photo-1558642452-9d2a7deb7f62?w=800&q=80',
        },
      ],
    },
    'iron-rich': {
      'icon': Icons.favorite_rounded,
      'accent': Color(0xFFDC2626),
      'badge': '12 mg / 100g',
      'title': 'Iron Rich',
      'subtitle': 'Natural iron & minerals retained. Not refined, not bleached.',
      'heroUrl': 'https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=1200&q=80',
      'stats': [
        {'value': '12mg', 'label': 'Iron / 100g', 'icon': Icons.bloodtype},
        {'value': '60%', 'label': 'Daily RDI', 'icon': Icons.show_chart},
        {'value': '5+', 'label': 'Minerals', 'icon': Icons.science},
      ],
      'galleryUrls': [
        'https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=600&q=80',
        'https://images.unsplash.com/photo-1587049352851-8d4e89133924?w=600&q=80',
        'https://images.unsplash.com/photo-1615484477778-ca3b77940c25?w=600&q=80',
      ],
      'process': [
        {'step': '01', 'title': 'Mineral-Rich Soil', 'desc': 'Eastern UP soil naturally high in iron & calcium'},
        {'step': '02', 'title': 'Iron Kadhai', 'desc': 'Boiling adds bioavailable iron naturally'},
        {'step': '03', 'title': 'No Refining', 'desc': 'Zero chemical processing preserves minerals'},
        {'step': '04', 'title': 'Lab Verified', 'desc': 'NABL-tested: 12mg iron per 100g confirmed'},
      ],
      'sections': [
        {
          'heading': 'Natural Iron Content',
          'body': 'Our jaggery contains approximately 12 mg of iron per 100 grams — that is nearly 60% of the recommended daily intake for adult women. This iron is naturally present from the sugarcane soil and the iron kadhai boiling process.\n\nUnlike iron-fortified foods, the iron in our jaggery is in a form your body can absorb efficiently alongside the natural vitamin C and minerals present in unrefined cane juice.',
          'imageUrl': 'https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=800&q=80',
        },
        {
          'heading': 'Beyond Just Iron',
          'body': 'Jaggery is a natural source of calcium, phosphorus, magnesium, potassium, and zinc — all trace minerals that survive our minimal-processing method. When you sweeten with our jaggery, you are not just avoiding white sugar; you are actively adding micronutrients to your diet.',
          'imageUrl': 'https://images.unsplash.com/photo-1587049352851-8d4e89133924?w=800&q=80',
        },
        {
          'heading': 'Not Refined, Not Bleached',
          'body': 'White sugar goes through up to 17 stages of chemical refining including sulphur treatment, phosphoric acid clarification, and activated carbon bleaching. Our jaggery goes through exactly one stage — boiling and setting. That is it.',
          'imageUrl': 'https://images.unsplash.com/photo-1615484477778-ca3b77940c25?w=800&q=80',
        },
      ],
    },
    'farmer-direct': {
      'icon': Icons.handshake_rounded,
      'accent': Color(0xFF2563EB),
      'badge': 'Since 2018',
      'title': 'Farmer Direct',
      'subtitle': 'From sugarcane fields to your kitchen — no middlemen, no markup.',
      'heroUrl': 'https://images.unsplash.com/photo-1590321868156-e1b6a2e4e8c2?w=1200&q=80',
      'stats': [
        {'value': '500+', 'label': 'Sugarcane Farmers', 'icon': Icons.agriculture},
        {'value': '35%', 'label': 'Income ↑', 'icon': Icons.trending_up},
        {'value': '4', 'label': 'Districts', 'icon': Icons.map},
      ],
      'galleryUrls': [
        'https://images.unsplash.com/photo-1590321868156-e1b6a2e4e8c2?w=600&q=80',
        'https://images.unsplash.com/photo-1578911373434-0cb395d2cbfb?w=600&q=80',
        'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=600&q=80',
      ],
      'process': [
        {'step': '01', 'title': 'Cane Harvest', 'desc': 'Farmers cut fresh sugarcane from their fields'},
        {'step': '02', 'title': 'Same-Day Press', 'desc': 'Juice extracted within hours, boiled on-site'},
        {'step': '03', 'title': 'Fair Payment', 'desc': 'Direct bank transfer, 20-30% above mandi rates'},
        {'step': '04', 'title': 'Trace to Farm', 'desc': 'Lot number traces back to farmer & village'},
      ],
      'sections': [
        {
          'heading': 'From Their Fields to Your Kitchen',
          'body': 'We source sugarcane directly from over 500 smallholder farmers across Varanasi, Chandauli, Mirzapur, and Bhadohi districts in Eastern Uttar Pradesh — the heartland of India\'s jaggery belt.\n\nEvery farmer receives a guaranteed minimum price that is 20-30% above local mandi rates. No middlemen. No commission agents. No exploitation. Just a fair deal between the people who grow the cane and the families who eat our jaggery.',
          'imageUrl': 'https://images.unsplash.com/photo-1578911373434-0cb395d2cbfb?w=800&q=80',
        },
        {
          'heading': 'Sugarcane is Their Life',
          'body': 'These families have been growing sugarcane for generations along the Ganges basin. The rich alluvial soil of Eastern UP produces some of India\'s sweetest cane — ideal for jaggery, gur, and our derivative products like powder, chikki, and syrup.\n\nBefore Hari Om Traders, these farmers had no direct market access. Middlemen took 40-50% of the final price. We changed that. Today, the farmer earns more and you pay less.',
          'imageUrl': 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800&q=80',
        },
        {
          'heading': 'Village-Level Impact',
          'body': 'When you buy our jaggery powder, chikki, or kakvi, the money goes directly to farming families in villages along the Ganges. Since 2018, our model has helped participating families increase their annual income by an average of 35%.\n\nWe also fund school supplies, clean water access, and healthcare camps in partner villages. Your purchase isn\'t just a product — it\'s an investment in a community.',
          'imageUrl': 'https://images.unsplash.com/photo-1590321868156-e1b6a2e4e8c2?w=800&q=80',
        },
        {
          'heading': 'Traceable From Cane to Pack',
          'body': 'Every pack of our jaggery carries a lot number you can trace back to the district and harvest season. We publish our farmer price list annually because transparency isn\'t a marketing claim — it\'s a promise.\n\nOur jaggery derivatives — powder, chikki, syrup, kakvi — all start with the same sugarcane from the same farms. The only thing that changes is how we process it.',
          'imageUrl': 'https://images.unsplash.com/photo-1578911373434-0cb395d2cbfb?w=800&q=80',
        },
      ],
    },
    'lab-tested': {
      'icon': Icons.science_rounded,
      'accent': Color(0xFF7C3AED),
      'badge': 'COA with QR',
      'title': 'Lab Tested',
      'subtitle': 'Every batch tested for sulphur, sweetness & purity before packing.',
      'heroUrl': 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=1200&q=80',
      'stats': [
        {'value': '<3', 'label': 'mg/kg SO₂', 'icon': Icons.science},
        {'value': '100%', 'label': 'Batch Tested', 'icon': Icons.verified},
        {'value': 'QR', 'label': 'COA Access', 'icon': Icons.qr_code},
      ],
      'galleryUrls': [
        'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=600&q=80',
        'https://images.unsplash.com/photo-1582719471384-894fbb16e074?w=600&q=80',
        'https://images.unsplash.com/photo-1576086213369-97a306d36557?w=600&q=80',
      ],
      'process': [
        {'step': '01', 'title': 'Batch Sampled', 'desc': 'Every production batch is sampled'},
        {'step': '02', 'title': 'NABL Lab Test', 'desc': 'Tested at accredited laboratory'},
        {'step': '03', 'title': 'COA Generated', 'desc': 'Certificate of Analysis with full data'},
        {'step': '04', 'title': 'QR Code Linked', 'desc': 'Scan pack QR to see lab results'},
      ],
      'sections': [
        {
          'heading': 'Batch-by-Batch Testing',
          'body': 'Every single production batch is tested at an NABL-accredited laboratory before it is approved for packing. We test for sulphur dioxide levels, moisture content, reducing sugar, total sugar, lead, arsenic, and microbial contamination.\n\nIf any batch fails even one parameter, it is rejected. No exceptions.',
          'imageUrl': 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=800&q=80',
        },
        {
          'heading': 'Certificate of Analysis (COA)',
          'body': 'Each pack has a QR code that links to the actual Certificate of Analysis for that specific batch. Scan it and you will see the lab results, the testing date, and the farm of origin.\n\nWe do not hide behind vague "lab tested" claims. We show you the data.',
          'imageUrl': 'https://images.unsplash.com/photo-1582719471384-894fbb16e074?w=800&q=80',
        },
        {
          'heading': 'What We Test For',
          'body': '• Sulphur Dioxide: Must be < 10 mg/kg (our average: < 3 mg/kg)\n• Moisture: Must be < 10%\n• Lead: Must be < 0.5 mg/kg\n• Arsenic: Must be < 0.3 mg/kg\n• E. coli: Not detected\n• Yeast & Mold: < 100 CFU/g',
          'imageUrl': 'https://images.unsplash.com/photo-1576086213369-97a306d36557?w=800&q=80',
        },
      ],
    },
    'pan-india-48h': {
      'icon': Icons.bolt_rounded,
      'accent': Color(0xFF0891B2),
      'badge': 'Free over ₹499',
      'title': 'Pan-India 48h',
      'subtitle': 'Fresh-packed, shipped within 24h. Hygienic pouch + jar.',
      'heroUrl': 'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=1200&q=80',
      'stats': [
        {'value': '24h', 'label': 'Dispatch', 'icon': Icons.local_shipping},
        {'value': '2-4d', 'label': 'Delivery', 'icon': Icons.delivery_dining},
        {'value': '₹0', 'label': 'Ship >₹499', 'icon': Icons.inventory_2},
      ],
      'galleryUrls': [
        'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=600&q=80',
        'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=600&q=80',
        'https://images.unsplash.com/photo-1553413077-190dd305871c?w=600&q=80',
      ],
      'process': [
        {'step': '01', 'title': 'Order Placed', 'desc': 'Before 2 PM ships same day'},
        {'step': '02', 'title': 'Packed Fresh', 'desc': 'Food-grade pouches, moisture sealed'},
        {'step': '03', 'title': 'Shipped', 'desc': 'Delhivery / Blue Dart / India Post'},
        {'step': '04', 'title': 'Delivered', 'desc': '2-4 business days pan-India'},
      ],
      'sections': [
        {
          'heading': 'Fast Dispatch',
          'body': 'Orders placed before 2 PM are dispatched the same day from our facility in Varanasi. Orders after 2 PM ship the next morning. Average delivery time is 2-4 business days depending on your pin code.\n\nWe use a combination of Delhivery, Blue Dart, and India Post to ensure coverage even in remote areas.',
          'imageUrl': 'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=800&q=80',
        },
        {
          'heading': 'Packaging That Protects',
          'body': 'Our jaggery is packed in food-grade, resealable kraft pouches with an inner moisture barrier. Glass jar options are available for premium packs. Both formats protect against humidity, which is jaggery\'s biggest enemy.\n\nEvery shipment includes a freshness card with the packing date and best-before window.',
          'imageUrl': 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800&q=80',
        },
        {
          'heading': 'Free Shipping Over ₹499',
          'body': 'Orders above ₹499 ship free anywhere in India. Below that, flat-rate shipping of ₹49 applies. We keep it simple — no hidden fees, no surprise charges at checkout.\n\nFor bulk and corporate orders, contact us directly for custom shipping rates.',
          'imageUrl': 'https://images.unsplash.com/photo-1553413077-190dd305871c?w=800&q=80',
        },
      ],
    },
  };

  String get _featureKey => 'feature_${widget.slug}';

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _heroZoom = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))..repeat(reverse: true);
    _stickyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scrollCtrl = ScrollManager.instance.controllerFor(_featureKey)..addListener(_onScroll);
    // restore offset for back navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final saved = ScrollManager.instance.getOffset(_featureKey);
        if (saved > 0 && (_scrollCtrl.offset - saved).abs() > 1) {
          _scrollCtrl.jumpTo(saved.clamp(0, _scrollCtrl.position.maxScrollExtent));
        }
      }
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    // persist for browser back — restores same scroll block/position
    ScrollManager.instance.saveOffset(_featureKey, _scrollCtrl.offset);
    final max = _scrollCtrl.position.maxScrollExtent;
    final offset = _scrollCtrl.offset;
    final prog = max <= 0 ? 0.0 : (offset / max).clamp(0.0, 1.0);
    // relative thresholds — scale with viewport height
    final showStickyThreshold = _R.heroHeight(context) * 1.05;
    final showFabThreshold = _R.heroHeight(context) * 1.6;
    final shouldShowSticky = offset > showStickyThreshold;
    final shouldShowFab = offset > showFabThreshold;
    if (prog != _scrollProgress || shouldShowSticky != _showSticky || shouldShowFab != _showFab) {
      setState(() {
        _scrollProgress = prog;
        if (shouldShowSticky != _showSticky) {
          _showSticky = shouldShowSticky;
          if (_showSticky) {
            _stickyCtrl.forward();
          } else {
            _stickyCtrl.reverse();
          }
        }
        _showFab = shouldShowFab;
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    ScrollManager.instance.saveOffset(_featureKey, _scrollCtrl.hasClients ? _scrollCtrl.offset : ScrollManager.instance.getOffset(_featureKey));
    // don't dispose shared controller — ScrollManager owns it
    _entrance.dispose();
    _heroZoom.dispose();
    _stickyCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int i, int total) {
    final start = (i / total) * 0.55;
    return CurvedAnimation(parent: _entrance, curve: Interval(start.clamp(0, 1), (start + 0.45).clamp(0, 1), curve: Curves.easeOutCubic));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final feature = _features[widget.slug];
    if (feature == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feature')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF6B7280)),
            const SizedBox(height: 12),
            Text('Feature not found: ${widget.slug}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.go('/'), child: const Text('Go Home')),
          ]),
        ),
      );
    }
    final accent = feature['accent'] as Color;
    final icon = feature['icon'] as IconData;
    final badge = feature['badge'] as String;
    final title = feature['title'] as String;
    final subtitle = feature['subtitle'] as String;
    final heroUrl = feature['heroUrl'] as String;
    final stats = feature['stats'] as List<Map<String, dynamic>>;
    final galleryUrls = feature['galleryUrls'] as List<String>;
    final process = feature['process'] as List<Map<String, String>>;
    final sections = feature['sections'] as List<Map<String, String>>;
    const total = 7;

    // responsive outer constraints — max 1080 on desktop, 720 on tablet, full on phone
    final screenW = _R.w(context);
    final maxContentW = _R.isDesktop(context) ? 1080.0 : _R.isTablet(context) ? 760.0 : double.infinity;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          CustomScrollView(
            key: PageStorageKey<String>(_featureKey),
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _HeroAppBar(
                isDark: isDark,
                accent: accent,
                icon: icon,
                badge: badge,
                title: title,
                heroUrl: heroUrl,
                zoom: _heroZoom,
                scrollProgress: _scrollProgress,
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentW),
                    child: Padding(
                      // relative horizontal padding so content never touches edge
                      padding: EdgeInsets.symmetric(horizontal: screenW >= 1100 ? 24 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Reveal(delay: _stagger(0, total), child: _Subtitle(isDark: isDark, subtitle: subtitle, accent: accent)),
                          _Reveal(delay: _stagger(1, total), child: _StatStrip(isDark: isDark, stats: stats, accent: accent, entrance: _entrance)),
                          _Reveal(delay: _stagger(2, total), child: _GalleryCarousel(isDark: isDark, urls: galleryUrls, accent: accent)),
                          _Reveal(delay: _stagger(3, total), child: _ProcessTimeline(isDark: isDark, process: process, accent: accent, entrance: _entrance)),
                          _Reveal(delay: _stagger(4, total), child: _ContentSections(isDark: isDark, sections: sections, accent: accent, entrance: _entrance)),
                          _Reveal(delay: _stagger(5, total), child: _CtaSection(accent: accent)),
                          SizedBox(height: _R.isPhone(context) ? 96 : 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // scroll progress line — thin, relative
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedBuilder(
                animation: _scrollCtrl,
                builder: (_, __) => LinearProgressIndicator(
                  value: _scrollProgress,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ),
          // sticky bottom CTA — slides, width constrained relative
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _stickyCtrl, curve: Curves.easeOutCubic)),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentW),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenW >= 1100 ? 24 : 0),
                    child: _StickyBar(accent: accent, isDark: isDark, title: title),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _showFab ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: Padding(
          // keep FAB above sticky bar on small screens
          padding: EdgeInsets.only(bottom: _showSticky && _R.isPhone(context) ? 72 : 0),
          child: FloatingActionButton.small(
            heroTag: 'fab-top',
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 6,
            onPressed: () {
              HapticFeedback.lightImpact();
              _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
            },
            child: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
        ),
      ),
    );
  }
}

// ─── REVEAL ───
class _Reveal extends StatelessWidget {
  const _Reveal({required this.delay, required this.child});
  final Animation<double> delay;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: delay,
      builder: (_, c) => Opacity(
        opacity: delay.value,
        child: Transform.translate(offset: Offset(0, 24 * (1 - delay.value)), child: c),
      ),
      child: child,
    );
  }
}

// ─── HERO ───
class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.isDark, required this.accent, required this.icon, required this.badge, required this.title, required this.heroUrl, required this.zoom, required this.scrollProgress});
  final bool isDark;
  final Color accent;
  final IconData icon;
  final String badge;
  final String title;
  final String heroUrl;
  final AnimationController zoom;
  final double scrollProgress;

  @override
  Widget build(BuildContext context) {
    final hPad = _R.hPad(context);
    final heroH = _R.heroHeight(context);
    final isPhone = _R.isPhone(context);
    final isSmall = _R.isSmallPhone(context);

    // title scales with width: 30 on small phone → 52 on desktop
    final titleSize = _R.font(context, isSmall ? 28 : isPhone ? 32 : 42).clamp(24.0, 54.0);

    return SliverAppBar(
      expandedHeight: heroH,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF0B0E0F) : Colors.white,
      leadingWidth: 56,
      leading: Center(
        child: _TapScale(
          onTap: () {
            HapticFeedback.selectionClick();
            context.go('/');
          },
          child: Container(
            padding: EdgeInsets.all(isSmall ? 6 : 7),
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(_R.radius(context, 12)), border: Border.all(color: Colors.white24)),
            child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: isSmall ? 18 : 20),
          ),
        ),
      ),
      actions: [
        Center(
          child: _TapScale(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title shared!'), behavior: SnackBarBehavior.floating, backgroundColor: accent));
            },
            child: Container(
              margin: EdgeInsets.only(right: hPad * 0.6),
              padding: EdgeInsets.all(isSmall ? 6 : 7),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(_R.radius(context, 12)), border: Border.all(color: Colors.white24)),
              child: Icon(Icons.share_rounded, color: Colors.white, size: isSmall ? 16 : 18),
            ),
          ),
        )
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: zoom,
              builder: (_, child) {
                final s = 1.0 + zoom.value * 0.12;
                // parallax relative to hero height
                final parallax = scrollProgress * heroH * 0.14;
                return Transform.translate(
                  offset: Offset(0, -parallax),
                  child: Transform.scale(scale: s, child: child),
                );
              },
              child: Image.network(
                heroUrl,
                fit: BoxFit.cover,
                loadingBuilder: (c, child, prog) => prog == null ? child : Container(color: accent.withOpacity(0.15), child: Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2))),
                errorBuilder: (_, __, ___) => Container(color: accent.withOpacity(0.2)),
              ),
            ),
            // gradient + vignette
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.82)],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            // animated accent glow bottom — width relative
            Positioned(
              left: -_R.w(context) * 0.08,
              right: -_R.w(context) * 0.08,
              bottom: -24,
              height: heroH * 0.32,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [accent.withOpacity(0.35), Colors.transparent], radius: 1.2),
                ),
              ),
            ),
            Positioned(
              left: hPad,
              right: hPad,
              bottom: isPhone ? heroH * 0.07 : heroH * 0.085,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxTextW = constraints.maxWidth * (isPhone ? 0.96 : 0.82);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Badge(accent: accent, icon: icon, badge: badge),
                      SizedBox(height: isSmall ? 10 : 14),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
                        child: Hero(
                          tag: 'feature-$title',
                          child: Material(
                            color: Colors.transparent,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxTextW),
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: titleSize,
                                  color: Colors.white,
                                  letterSpacing: isSmall ? -0.5 : -0.8,
                                  height: 1.05,
                                  shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 6 : 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child)),
                        child: Row(
                          children: [
                            Container(width: isSmall ? 22 : 28, height: 3, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Hari Om Traders • Since 2018',
                                style: TextStyle(color: Colors.white70, fontSize: _R.font(context, 12).clamp(10.5, 13.5), fontWeight: FontWeight.w600, letterSpacing: 0.4),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatefulWidget {
  const _Badge({required this.accent, required this.icon, required this.badge});
  final Color accent;
  final IconData icon;
  final String badge;
  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final isSmall = _R.isSmallPhone(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Container(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 14, vertical: isSmall ? 5 : 7),
        decoration: BoxDecoration(
          color: widget.accent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.35 + _c.value * 0.2), blurRadius: 10 + _c.value * 6, spreadRadius: _c.value * 1.5)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: isSmall ? 13 : 15, color: Colors.white),
          SizedBox(width: isSmall ? 5 : 6),
          Text(widget.badge, style: TextStyle(fontWeight: FontWeight.w800, fontSize: _R.font(context, isSmall ? 11 : 12.5).clamp(10.5, 13.5), color: Colors.white, letterSpacing: 0.3)),
        ]),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;
  @override
  State<_TapScale> createState() => _TapScaleState();
}
class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120)); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(), onTapUp: (_) { _c.reverse(); widget.onTap(); }, onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(animation: _c, builder: (_, ch) => Transform.scale(scale: 1 - _c.value * 0.12, child: ch), child: widget.child),
    );
  }
}

// ─── SUBTITLE ───
class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.isDark, required this.subtitle, required this.accent});
  final bool isDark; final String subtitle; final Color accent;
  @override
  Widget build(BuildContext context) {
    final hPad = _R.hPad(context);
    final subtitleSize = _R.font(context, 16.5).clamp(14.5, 18.0);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
      padding: EdgeInsets.all(_R.isSmallPhone(context) ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : Colors.white,
        borderRadius: BorderRadius.circular(_R.radius(context, 16)),
        border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 3, height: _R.isSmallPhone(context) ? 40 : 48, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(child: Text(subtitle, style: TextStyle(fontSize: subtitleSize, height: 1.55, color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF374151), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ─── STAT STRIP ───
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.isDark, required this.stats, required this.accent, required this.entrance});
  final bool isDark; final List<Map<String, dynamic>> stats; final Color accent; final AnimationController entrance;
  @override
  Widget build(BuildContext context) {
    final hPad = _R.hPad(context);
    final isSmall = _R.isSmallPhone(context);
    // on very small phones, allow tighter padding
    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 18, hPad, 0),
      padding: EdgeInsets.symmetric(vertical: isSmall ? 14 : 18, horizontal: isSmall ? 4 : 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : Colors.white,
        borderRadius: BorderRadius.circular(_R.radius(context, 20)),
        border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.18 : 0.07), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final idx = e.key; final s = e.value;
          return Expanded(
            child: _StatItem(isDark: isDark, accent: accent, icon: s['icon'] as IconData, value: s['value'] as String, label: s['label'] as String, delay: 300 + idx * 180, showDivider: idx < stats.length - 1),
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem extends StatefulWidget {
  const _StatItem({required this.isDark, required this.accent, required this.icon, required this.value, required this.label, required this.delay, required this.showDivider});
  final bool isDark; final Color accent; final IconData icon; final String value; final String label; final int delay; final bool showDivider;
  @override
  State<_StatItem> createState() => _StatItemState();
}
class _StatItemState extends State<_StatItem> with SingleTickerProviderStateMixin {
  late AnimationController _c; bool _pressed = false;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700)); Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); }); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final isSmall = _R.isSmallPhone(context);
    final valueSize = _R.font(context, _pressed ? 22 : 19).clamp(15.0, 23.0);
    final labelSize = _R.font(context, 11).clamp(9.5, 12.0);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: widget.showDivider ? BoxDecoration(border: Border(right: BorderSide(color: widget.isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)))) : null,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Opacity(
            opacity: _c.value,
            child: Transform.translate(offset: Offset(0, 12 * (1 - _c.value)), child: Transform.scale(scale: 0.9 + 0.1 * _c.value, child: child)),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.all(_pressed ? 8 : (isSmall ? 5 : 6)),
                decoration: BoxDecoration(color: _pressed ? widget.accent.withOpacity(0.14) : widget.accent.withOpacity(0.10), borderRadius: BorderRadius.circular(_R.radius(context, 12))),
                child: Icon(widget.icon, size: isSmall ? 16 : 20, color: widget.accent),
              ),
              SizedBox(height: isSmall ? 6 : 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: valueSize, color: _pressed ? widget.accent : (widget.isDark ? Colors.white : const Color(0xFF0B0E0F))),
                child: Text(widget.value, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 2),
              Text(widget.label, textAlign: TextAlign.center, style: TextStyle(fontSize: labelSize, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: widget.isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── GALLERY CAROUSEL ───
class _GalleryCarousel extends StatefulWidget {
  const _GalleryCarousel({required this.isDark, required this.urls, required this.accent});
  final bool isDark; final List<String> urls; final Color accent;
  @override
  State<_GalleryCarousel> createState() => _GalleryCarouselState();
}
class _GalleryCarouselState extends State<_GalleryCarousel> {
  late PageController _pc;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.92);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // viewportFraction relative to screen width
    final w = _R.w(context);
    final vf = w >= 1100 ? 0.48 : w >= 700 ? 0.62 : 0.92;
    if (_pc.hasClients) {
      // recreate with new fraction if breakpoint crossed — simple: keep 0.92 for now
    }
    // ignore: unused_local_variable
    vf;
  }

  void _openPreview(int i) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: _R.hPad(context), vertical: 24),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Hero(
                tag: 'gallery-$i',
                child: ClipRRect(borderRadius: BorderRadius.circular(_R.radius(context, 16)), child: Image.network(widget.urls[i], fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(height: 300, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white54)))),
              ),
            ),
            Positioned(top: 8, right: 8, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.black54))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hPad = _R.hPad(context);
    final galleryH = _R.galleryHeight(context);
    final headerSize = _R.font(context, 18).clamp(16.0, 20.0);
    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 4, height: _R.font(context, 20).clamp(18, 22), decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text('Gallery', style: TextStyle(fontWeight: FontWeight.w800, fontSize: headerSize, color: widget.isDark ? Colors.white : const Color(0xFF0B0E0F))),
            const Spacer(),
            Text('${_idx + 1} / ${widget.urls.length}', style: TextStyle(fontSize: _R.font(context, 12).clamp(11, 13), fontWeight: FontWeight.w700, color: widget.isDark ? Colors.white54 : const Color(0xFF9CA3AF)))
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: galleryH,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return PageView.builder(
                  controller: _pc,
                  onPageChanged: (v) => setState(() => _idx = v),
                  itemCount: widget.urls.length,
                  itemBuilder: (_, i) {
                    final url = widget.urls[i];
                    final isActive = _idx == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.only(right: i == widget.urls.length - 1 ? 0 : 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_R.radius(context, 18)),
                        border: Border.all(color: isActive ? widget.accent.withOpacity(0.6) : (widget.isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)), width: isActive ? 2 : 1),
                        boxShadow: isActive ? [BoxShadow(color: widget.accent.withOpacity(0.25), blurRadius: 16)] : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_R.radius(context, 16)),
                        child: GestureDetector(
                          onTap: () => _openPreview(i),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(tag: 'gallery-$i', child: Image.network(url, fit: BoxFit.cover, loadingBuilder: (c, ch, p) => p == null ? ch : Container(color: widget.accent.withOpacity(0.12), child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent)))), errorBuilder: (_, __, ___) => Container(color: widget.isDark ? const Color(0xFF1A1F24) : const Color(0xFFF3F4F6), child: const Icon(Icons.image, color: Color(0xFF9CA3AF))))),
                              Positioned(right: 10, bottom: 10, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.zoom_out_map_rounded, size: _R.isSmallPhone(context) ? 14 : 16, color: Colors.white))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.urls.length, (i) {
              final active = i == _idx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? (_R.isSmallPhone(context) ? 18 : 22) : 8,
                height: 8,
                decoration: BoxDecoration(color: active ? widget.accent : (widget.isDark ? Colors.white24 : const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(100)),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── PROCESS TIMELINE ───
class _ProcessTimeline extends StatelessWidget {
  const _ProcessTimeline({required this.isDark, required this.process, required this.accent, required this.entrance});
  final bool isDark; final List<Map<String, String>> process; final Color accent; final AnimationController entrance;
  @override
  Widget build(BuildContext context) {
    final hPad = _R.hPad(context);
    final headerSize = _R.font(context, 18).clamp(16.0, 20.0);
    final titleSize = _R.font(context, 14.5).clamp(13.0, 16.0);
    final descSize = _R.font(context, 13).clamp(11.5, 14.0);
    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 28, hPad, 0),
      padding: EdgeInsets.all(_R.isSmallPhone(context) ? 14 : 18),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(_R.radius(context, 20)), border: Border.all(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.06), blurRadius: 18, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 4, height: _R.font(context, 20).clamp(18, 22), decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text('How It Works', style: TextStyle(fontWeight: FontWeight.w800, fontSize: headerSize, color: isDark ? Colors.white : const Color(0xFF0B0E0F)))]),
          const SizedBox(height: 18),
          ...process.asMap().entries.map((e) {
            final i = e.key; final step = e.value; final isLast = i == process.length - 1;
            final anim = CurvedAnimation(parent: entrance, curve: Interval((0.35 + i * 0.08).clamp(0, 1), (0.55 + i * 0.08).clamp(0, 1), curve: Curves.easeOutCubic));
            return AnimatedBuilder(
              animation: anim,
              builder: (_, child) => Opacity(opacity: anim.value, child: Transform.translate(offset: Offset(18 * (1 - anim.value), 0), child: child)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(children: [
                    _StepDot(step: step['step']!, accent: accent, isActive: true),
                    if (!isLast) Container(width: 2, height: _R.isSmallPhone(context) ? 28 : 36, decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withOpacity(0.55), accent.withOpacity(0.08)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                  ]),
                  SizedBox(width: _R.isSmallPhone(context) ? 10 : 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 2),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(step['title']!, style: TextStyle(fontWeight: FontWeight.w800, fontSize: titleSize, color: isDark ? Colors.white : const Color(0xFF0B0E0F))),
                        const SizedBox(height: 4),
                        Text(step['desc']!, style: TextStyle(fontSize: descSize, height: 1.45, color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
                      ]),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: _R.isSmallPhone(context) ? 16 : 18, color: accent.withOpacity(0.6)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepDot extends StatefulWidget {
  const _StepDot({required this.step, required this.accent, required this.isActive});
  final String step; final Color accent; final bool isActive;
  @override
  State<_StepDot> createState() => _StepDotState();
}
class _StepDotState extends State<_StepDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final dotSize = _R.isSmallPhone(context) ? 36.0 : 42.0;
    final fontSize = _R.font(context, 13).clamp(11.5, 13.5);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Container(
        width: dotSize, height: dotSize,
        decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(_R.radius(context, 12)), boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.30 + _c.value * 0.15), blurRadius: 8 + _c.value * 6)]),
        child: Center(child: Text(widget.step, style: TextStyle(fontWeight: FontWeight.w900, fontSize: fontSize, color: Colors.white))),
      ),
    );
  }
}

// ─── CONTENT SECTIONS ───
class _ContentSections extends StatelessWidget {
  const _ContentSections({required this.isDark, required this.sections, required this.accent, required this.entrance});
  final bool isDark; final List<Map<String, String>> sections; final Color accent; final AnimationController entrance;
  @override
  Widget build(BuildContext context) {
    final hPad = _R.hPad(context);
    final isWide = _R.isWide(context);
    // on wide screens show 2-column grid, else single column — element position relative to grid
    if (isWide) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final cardW = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: sections.asMap().entries.map((e) {
                final i = e.key; final s = e.value;
                final anim = CurvedAnimation(parent: entrance, curve: Interval((0.60 + i * 0.08).clamp(0, 1), (0.82 + i * 0.08).clamp(0, 1), curve: Curves.easeOutCubic));
                return SizedBox(
                  width: cardW,
                  child: AnimatedBuilder(
                    animation: anim,
                    builder: (_, child) => Opacity(opacity: anim.value, child: Transform.translate(offset: Offset(0, 28 * (1 - anim.value)), child: child)),
                    child: _ExpandableCard(index: i, heading: s['heading']!, body: s['body']!, imageUrl: s['imageUrl']!, accent: accent, isDark: isDark),
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
      child: Column(
        children: sections.asMap().entries.map((e) {
          final i = e.key; final s = e.value;
          final anim = CurvedAnimation(parent: entrance, curve: Interval((0.60 + i * 0.08).clamp(0, 1), (0.82 + i * 0.08).clamp(0, 1), curve: Curves.easeOutCubic));
          return AnimatedBuilder(
            animation: anim,
            builder: (_, child) => Opacity(opacity: anim.value, child: Transform.translate(offset: Offset(0, 28 * (1 - anim.value)), child: child)),
            child: _ExpandableCard(index: i, heading: s['heading']!, body: s['body']!, imageUrl: s['imageUrl']!, accent: accent, isDark: isDark),
          );
        }).toList(),
      ),
    );
  }
}

class _ExpandableCard extends StatefulWidget {
  const _ExpandableCard({required this.index, required this.heading, required this.body, required this.imageUrl, required this.accent, required this.isDark});
  final int index; final String heading; final String body; final String imageUrl; final Color accent; final bool isDark;
  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}
class _ExpandableCardState extends State<_ExpandableCard> with SingleTickerProviderStateMixin {
  bool _expanded = true;
  bool _pressed = false;
  late AnimationController _arrow;
  @override
  void initState() { super.initState(); _arrow = AnimationController(vsync: this, duration: const Duration(milliseconds: 250)); }
  @override
  void dispose() { _arrow.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final isSmall = _R.isSmallPhone(context);
    final headingSize = _R.font(context, 17).clamp(15.0, 19.0);
    final bodySize = _R.font(context, 14).clamp(12.5, 15.0);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expanded = !_expanded);
        if (_expanded) {
          _arrow.reverse();
        } else {
          _arrow.forward();
        }
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.only(bottom: isSmall ? 14 : 18),
          decoration: BoxDecoration(color: widget.isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: BorderRadius.circular(_R.radius(context, 20)), border: Border.all(color: _pressed ? widget.accent.withOpacity(0.5) : (widget.isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)), width: _pressed ? 1.4 : 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(widget.isDark ? 0.18 : 0.07), blurRadius: 16, offset: const Offset(0, 8))]),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: _R.isWide(context) ? 16 / 10 : 16 / 9,
                    child: Image.network(widget.imageUrl, fit: BoxFit.cover, loadingBuilder: (c, ch, p) => p == null ? ch : Container(color: widget.accent.withOpacity(0.12), child: Center(child: CircularProgressIndicator(color: widget.accent, strokeWidth: 2))), errorBuilder: (_, __, ___) => Container(color: widget.accent.withOpacity(0.08), child: const Icon(Icons.image, color: Color(0xFF9CA3AF), size: 36))),
                  ),
                  Positioned(left: 12, top: 12, child: Container(padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10, vertical: isSmall ? 4 : 6), decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.4), blurRadius: 10)]), child: Text('0${widget.index + 1}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _R.font(context, 12).clamp(11, 13))))),
                  Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.22)])))),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(isSmall ? 14 : 16, isSmall ? 14 : 16, isSmall ? 14 : 16, isSmall ? 12 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: Text(widget.heading, style: TextStyle(fontWeight: FontWeight.w800, fontSize: headingSize, height: 1.25, color: widget.isDark ? Colors.white : const Color(0xFF0B0E0F)))), RotationTransition(turns: Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _arrow, curve: Curves.easeOutCubic)), child: Container(padding: EdgeInsets.all(isSmall ? 5 : 6), decoration: BoxDecoration(color: widget.accent.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.keyboard_arrow_down_rounded, size: isSmall ? 18 : 20, color: widget.accent)))]),
                    AnimatedCrossFade(firstChild: const SizedBox.shrink(), secondChild: Padding(padding: const EdgeInsets.only(top: 12), child: Text(widget.body, style: TextStyle(fontSize: bodySize, height: 1.7, color: widget.isDark ? Colors.white70 : const Color(0xFF374151)))), crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst, duration: const Duration(milliseconds: 260), sizeCurve: Curves.easeOutCubic),
                    if (!_expanded) Padding(padding: const EdgeInsets.only(top: 8), child: Text(widget.body.split('\n').first, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: _R.font(context, 13.5).clamp(12, 14), height: 1.6, color: widget.isDark ? Colors.white54 : const Color(0xFF6B7280)))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CTA ───
class _CtaSection extends StatefulWidget {
  const _CtaSection({required this.accent});
  final Color accent;
  @override
  State<_CtaSection> createState() => _CtaSectionState();
}
class _CtaSectionState extends State<_CtaSection> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  @override
  void initState() { super.initState(); _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true); }
  @override
  void dispose() { _pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final hPad = _R.hPad(context);
    final isPhone = _R.isPhone(context);
    final titleSize = _R.font(context, 17).clamp(15.0, 19.0);
    final descSize = _R.font(context, 13).clamp(11.5, 14.0);
    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 6, hPad, 8),
      padding: EdgeInsets.all(_R.isSmallPhone(context) ? 16 : 22),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.accent, Color.lerp(widget.accent, Colors.black, 0.18)!], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(_R.radius(context, 20)), boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))]),
      child: isPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready to taste the difference?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: titleSize, color: Colors.white, height: 1.2)),
                const SizedBox(height: 6),
                Text('Try our jaggery today — organic, wood-pressed & lab tested.', style: TextStyle(fontSize: descSize, height: 1.4, color: Colors.white.withOpacity(0.88))),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) => Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.12 + _pulse.value * 0.12), blurRadius: 12 + _pulse.value * 8, spreadRadius: _pulse.value * 2)]), child: child),
                    child: _TapScale(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.go('/products');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10)]),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [Text('Shop Now', style: TextStyle(fontWeight: FontWeight.w900, color: widget.accent, fontSize: _R.font(context, 14).clamp(13, 15))), const SizedBox(width: 6), Icon(Icons.arrow_forward_rounded, size: 16, color: widget.accent)]),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ready to taste the difference?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: titleSize, color: Colors.white, height: 1.2)), const SizedBox(height: 6), Text('Try our jaggery today — organic, wood-pressed & lab tested.', style: TextStyle(fontSize: descSize, height: 1.4, color: Colors.white.withOpacity(0.88)))])),
                const SizedBox(width: 14),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.12 + _pulse.value * 0.12), blurRadius: 12 + _pulse.value * 8, spreadRadius: _pulse.value * 2)]), child: child),
                  child: _TapScale(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.go('/products');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10)]),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Text('Shop Now', style: TextStyle(fontWeight: FontWeight.w900, color: widget.accent, fontSize: _R.font(context, 14).clamp(13, 15))), const SizedBox(width: 6), Icon(Icons.arrow_forward_rounded, size: 16, color: widget.accent)]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StickyBar extends StatelessWidget {
  const _StickyBar({required this.accent, required this.isDark, required this.title});
  final Color accent; final bool isDark; final String title;
  @override
  Widget build(BuildContext context) {
    final isSmall = _R.isSmallPhone(context);
    final titleSize = _R.font(context, 13).clamp(11.5, 14.0);
    final subSize = _R.font(context, 11.5).clamp(10.0, 12.5);
    return Container(
      padding: EdgeInsets.fromLTRB(_R.hPad(context), 12, _R.hPad(context), 12 + MediaQuery.of(context).padding.bottom * 0.45),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, border: Border(top: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, -6))]),
      child: Row(
        children: [
          Container(padding: EdgeInsets.all(isSmall ? 7 : 9), decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(_R.radius(context, 12))), child: Icon(Icons.shopping_bag_rounded, color: accent, size: isSmall ? 16 : 18)),
          SizedBox(width: isSmall ? 10 : 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: titleSize, color: isDark ? Colors.white : const Color(0xFF0B0E0F)), overflow: TextOverflow.ellipsis), Text('Free delivery over ₹499 • 2-4 days', style: TextStyle(fontSize: subSize, color: isDark ? Colors.white54 : const Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)])),
          SizedBox(width: isSmall ? 10 : 12),
          FilledButton(onPressed: () { HapticFeedback.mediumImpact(); context.go('/products'); }, style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 22, vertical: isSmall ? 10 : 12)), child: Text('Shop Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: _R.font(context, 13).clamp(12, 14)))),
        ],
      ),
    );
  }
}
