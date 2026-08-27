// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hm_ent/main.dart';

void main() {
  testWidgets('App builds and shows Hari Om Traders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that app builds without crash and shows brand
    expect(find.byType(MaterialApp), findsOneWidget);
    // At least one of these should be visible (header or home)
    final brand = find.textContaining('Hari Om');
    final products = find.textContaining('Shop organic jaggery');
    final home = find.textContaining('Home');
    expect(brand.evaluate().isNotEmpty || products.evaluate().isNotEmpty || home.evaluate().isNotEmpty, isTrue);
  });
}
