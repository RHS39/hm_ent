import 'package:flutter/material.dart';

/// Minimal footer – height identical to header (64px) for hariomtraders.com symmetry.
///
/// Icons and labels removed. Height, background, border and padding match
/// `AppHeader` (64px, 1px border) so header/footer are visually identical in size.
class AppFooter extends StatelessWidget {
  const AppFooter({
    super.key,
    this.copyrightText = '© 2026 Hari Om Traders Markets, Inc. • hariomtraders.com • All rights reserved.',
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.showDivider = true,
    this.height = 64,
  });

  /// Copyright / branding text.
  final String copyrightText;

  /// Background color. Defaults to header's Hari Om Traders white / #0B0E0F to stay identical.
  final Color? backgroundColor;

  /// Foreground / text color. Defaults to header's black/white.
  final Color? foregroundColor;

  /// Inner padding – horizontal only to keep 64px height exact (vertical centered).
  final EdgeInsetsGeometry padding;

  /// Whether to show top border (mirrors header's bottom border).
  final bool showDivider;

  /// Height identical to header – 64px.
  final double height;

  @override
  Widget build(BuildContext context) {
    // Hidden per request – keep file for future use but render nothing.
    // To show again, restore Container implementation.
    return const SizedBox.shrink();
  }
}
