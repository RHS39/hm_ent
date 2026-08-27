import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_header.dart';
import '../services/scroll_manager.dart';

/// Dynamic content page – renders content based on [slug] / id from route.
///
/// Route: `/content/:slug`  or `/product/:id`  or `/page/:slug`
///
/// Example:
/// ```dart
/// context.go('/content/about-us');
/// context.go('/product/3');
/// ```
class DynamicContentPage extends StatefulWidget {
  const DynamicContentPage({
    super.key,
    required this.slug,
    this.title,
    this.body,
  });

  /// Slug / id from route, e.g. "about-us", "3"
  final String slug;

  /// Optional override title. Defaults to formatted slug.
  final String? title;

  /// Optional override body.
  final String? body;

  @override
  State<DynamicContentPage> createState() => _DynamicContentPageState();
}

class _DynamicContentPageState extends State<DynamicContentPage> {
  late final ScrollController _scrollCtrl;

  String get _scrollKey => 'dynamic_${widget.slug}';

  String get _displayTitle {
    if (widget.title != null) return widget.title!;
    return widget.slug
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static const Map<String, String> _demoContent = {
    'about-us': 'Hari Om Traders (hariomtraders.com) is a commission-free investing platform on a mission to democratize finance for all. Trade stocks, ETFs, options and crypto with an intuitive mobile experience.',
    'privacy-policy': 'Hari Om Traders privacy policy demo — hariomtraders.com/legal. We respect your privacy and handle data securely. Contact support@hariomtraders.com for details.',
    'terms': 'Terms & Conditions: All products are subject to availability. Prices are inclusive of GST. Returns accepted within 7 days.',
    'faq': 'Frequently Asked Questions:\n\nQ: Delivery time?\nA: 2-5 business days pan-India.\n\nQ: Return policy?\nA: 7-day return.',
  };

  String get _displayBody {
    if (widget.body != null) return widget.body!;
    return _demoContent[widget.slug.toLowerCase()] ??
        'Dynamic page for "${widget.slug}".\n\nThis is placeholder content. In production, fetch from API/CMS using slug = "${widget.slug}".\n\nRoute: /content/${widget.slug}';
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollManager.instance.controllerFor(_scrollKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final saved = ScrollManager.instance.getOffset(_scrollKey);
        if (saved > 0 && (_scrollCtrl.offset - saved).abs() > 1) {
          _scrollCtrl.jumpTo(saved.clamp(0, _scrollCtrl.position.maxScrollExtent));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: _displayTitle,
        subtitle: 'Dynamic Content',
        actions: [
          IconButton(icon: const Icon(Icons.home_outlined), tooltip: 'Home', onPressed: () => context.go('/')),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              key: PageStorageKey<String>(_scrollKey),
              controller: _scrollCtrl,
              padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 360 ? 12 : 16),
              children: [
                Container(
                  padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 360 ? 14 : 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: MediaQuery.sizeOf(context).width < 360 ? 18 : null)),
                      const SizedBox(height: 8),
                      Text('Slug: ${widget.slug}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(_displayBody, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(onPressed: () => context.canPop() ? context.pop() : context.go('/'), icon: const Icon(Icons.arrow_back), label: const Text('Go Back')),
                    OutlinedButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.home), label: const Text('Home')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
