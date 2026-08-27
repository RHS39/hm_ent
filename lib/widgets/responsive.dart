import 'package:flutter/material.dart';

/// Central responsive helpers – no overflow on any screen size / aspect ratio.
///
/// Usage:
///   final r = Responsive.of(context);
///   r.isMobile, r.isTablet, r.isDesktop
///   Responsive.font(context, mobile: 22, tablet: 26, desktop: 38)
class Responsive {
  const Responsive._(this.context);
  final BuildContext context;

  static Responsive of(BuildContext context) => Responsive._(context);

  static const double mobileMax = 600;
  static const double tabletMax = 1100;

  double get width => MediaQuery.sizeOf(context).width;
  double get height => MediaQuery.sizeOf(context).height;
  double get aspect => width == 0 || height == 0 ? 1 : width / height;
  bool get isPortrait => height > width;
  bool get isLandscape => !isPortrait;
  bool get isMobile => width < mobileMax;
  bool get isTablet => width >= mobileMax && width < tabletMax;
  bool get isDesktop => width >= tabletMax;
  bool get isNarrow => width < 360;
  bool get isVeryNarrow => width < 320;
  // Height-aware
  bool get isShort => height < 600;
  bool get isVeryShort => height < 480;

  static double clampWidth(BuildContext c, double min, double ideal, double max) {
    return MediaQuery.sizeOf(c).width.clamp(min, max).toDouble();
  }

  static double font(BuildContext context, {required double mobile, double? tablet, required double desktop}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobileMax) return mobile;
    if (w < tabletMax) return tablet ?? (mobile + desktop) / 2;
    return desktop;
  }

  static double spacing(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 8;
    if (w < 600) return 12;
    return 16;
  }

  // Wrap-safe padding that never overflows on 280px watch widths
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: isVeryNarrow ? 8 : isNarrow ? 12 : 16,
        vertical: 12,
      );

  // Grid cross count that respects width AND height (landscape short)
  int gridCross({required int mobile, required int tablet, required int desktop}) {
    if (isDesktop && !isShort) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }
}

/// Responsive text that scales with width and never overflows.
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(this.text, {super.key, required this.style, this.maxLines, this.overflow, this.textAlign, this.minScale = 0.7});
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final double minScale;
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.center ? Alignment.center : Alignment.centerLeft,
      child: Text(text, style: style, maxLines: maxLines, overflow: overflow, textAlign: textAlign),
    );
  }
}

/// Safe wrapper that prevents horizontal overflow on any width down to 280px
class SafeHorizontal extends StatelessWidget {
  const SafeHorizontal({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: c.maxWidth),
          child: child,
        ),
      );
    });
  }
}
