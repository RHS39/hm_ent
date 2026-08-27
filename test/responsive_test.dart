import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_ent/pages/home_page.dart';
import 'package:hm_ent/pages/products_page.dart';
import 'package:hm_ent/widgets/app_header.dart';

void main() {
  // Sizes to test: width x height in logical pixels. Also test aspect ratios.
  final sizes = <Size>[
    const Size(280, 653), // very narrow
    const Size(320, 568), // iPhone SE
    const Size(360, 740),
    const Size(375, 812),
    const Size(414, 896),
    const Size(600, 800), // tablet portrait
    const Size(768, 1024),
    const Size(800, 600), // tablet landscape short
    const Size(1024, 768), // landscape
    const Size(1280, 800),
    const Size(1920, 1080), // desktop
    const Size(2560, 1440), // ultra wide
    const Size(3440, 1440), // 21:9
    const Size(412, 300), // landscape very short height
  ];

  for (final size in sizes) {
    testWidgets('AppHeader no overflow at ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const AppHeader(title: 'Hari Om Traders', subtitle: 'Test', navIndex: 0, onNavSelected: null),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in sizes) {
    testWidgets('HomeContent no overflow at ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final errs = <FlutterErrorDetails>[];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          errs.add(details);
        }
        // do not call presentError to avoid console spam hang
      };
      addTearDown(() => FlutterError.onError = oldHandler);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeContent())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));
      FlutterError.onError = oldHandler;
      if (errs.isNotEmpty) {
        for (final e in errs) {
          // ignore: avoid_print
          print('ERR at $size: ${e.toString()}');
        }
      }
      final exc = tester.takeException();
      if (exc != null) {
        print('takeException at $size: $exc');
      }
      expect(errs, isEmpty, reason: 'Overflow at $size');
      expect(exc, isNull);
    });
  }

  for (final size in [const Size(280, 653), const Size(320, 568), const Size(360, 740), const Size(768, 1024), const Size(1920, 1080)]) {
    testWidgets('ProductsContent no overflow ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductsContent(
              products: const [
                Product(id: '1', productId: '01', name: 'Chocolaty Gud 700g Very Long Name That Could Overflow At Small Size Extra', price: 299, imagePlaceholder: Icons.grain, description: 'Very long description that might overflow if not handled properly on small screens extra text', imageAsset: null),
                Product(id: '2', productId: '02', name: 'Organic Jaggery Cubes 1kg', price: 229, imagePlaceholder: Icons.spa, description: 'Traditional hand-cut cubes', imageAsset: null),
              ],
              query: '',
              sort: 'Featured',
              onQueryChanged: (_) {},
              onSortChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  }
}
