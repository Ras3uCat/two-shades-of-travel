import 'package:flutter/foundation.dart';

/// EPlatform — compile-time platform detection helpers.
///
/// Use these instead of kIsWeb directly so the intent is clear in widget code.
/// [isNative] is true on iOS and Android native builds, false on web (all viewports).
class EPlatform {
  EPlatform._();

  /// True on iOS/Android native. False on web (desktop or mobile browser).
  static const bool isNative = !kIsWeb;

  /// True on web (desktop or mobile browser).
  static const bool isWeb = kIsWeb;

  /// Clamp animation duration for native — long durations feel sluggish on mobile.
  /// Widgets that respect personality animation speed should use this on native.
  ///
  /// Example:
  ///   duration: EPlatform.nativeAnim(pt.animDuration)
  static Duration nativeAnim(Duration d) =>
      isNative && d.inMilliseconds > 260
          ? const Duration(milliseconds: 240)
          : d;
}
