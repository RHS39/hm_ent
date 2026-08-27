import 'package:flutter/widgets.dart';

/// Global scroll-position store.
/// Mirrors browser session history `scrollRestoration: manual` —
/// remembers vertical offset per route so back navigation restores
/// the exact viewport position instead of jumping to top.
///
/// Works for Flutter web where each `GoRoute` rebuilds its
/// `CustomScrollView` / `SingleChildScrollView` from scratch.
/// Without this the widget is created with offset 0 on every
/// navigation, which feels like the browser "forgot" scroll.
///
/// Usage:
/// ```dart
/// final ctrl = ScrollManager.controllerFor('home');
/// // hook into CustomScrollView / SingleChildScrollView
/// CustomScrollView(controller: ctrl, key: PageStorageKey('home'), ...)
/// ```
/// The controller is lazily created with `initialScrollOffset`
/// taken from the last saved value. A listener keeps the map
/// up-to-date on every scroll. On dispose we persist once more.
class ScrollManager {
  ScrollManager._();

  static final ScrollManager instance = ScrollManager._();

  /// Global [PageStorageBucket] that is shared by all pages.
  /// When a scrollable is given a [PageStorageKey] it automatically
  /// writes/reads its offset into this bucket, so even if the
  /// [State] object is disposed (GoRouter `go()` replaces the page)
  /// the offset survives in the bucket. The manual [_offsets] map
  /// is the fallback / source of truth for `initialScrollOffset`.
  static final PageStorageBucket bucket = PageStorageBucket();

  final Map<String, double> _offsets = {};
  final Map<String, ScrollController> _controllers = {};

  double getOffset(String key) => _offsets[key] ?? 0;

  void saveOffset(String key, double offset) {
    if (!offset.isNaN && offset.isFinite) _offsets[key] = offset;
  }

  /// Returns a shared [ScrollController] for [key].
  /// The controller is created once with the stored offset and
  /// kept alive until [disposeController] is called. Re-using the
  /// same instance across rebuilds avoids jump-to-0 flicker.
  ScrollController controllerFor(String key) {
    final existing = _controllers[key];
    if (existing != null) return existing;

    final c = ScrollController(initialScrollOffset: getOffset(key));
    c.addListener(() {
      // save while scrolling
      if (c.hasClients) saveOffset(key, c.offset);
    });
    _controllers[key] = c;
    return c;
  }

  void disposeController(String key) {
    final c = _controllers.remove(key);
    if (c != null) {
      if (c.hasClients) saveOffset(key, c.offset);
      c.dispose();
    }
  }

  /// Persist manually — call from `dispose()` or `deactivate()`
  /// when the state's controller is owned locally (not via
  /// [controllerFor]).
  void persist(String key, ScrollController? c) {
    if (c == null) return;
    if (c.hasClients) saveOffset(key, c.offset);
  }
}
