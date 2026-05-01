import 'package:flutter/foundation.dart';

/// ESpacing — fixed spacing scale used throughout all modules.
/// Based on an 8pt grid. Widgets use these constants, never raw numbers.
class ESpacing {
  ESpacing._();

  static const double xxs  = 4.0;
  static const double xs   = 8.0;
  static const double sm   = 12.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;
  static const double huge = 96.0;
  static const double epic = 128.0;

  // Page padding
  static const double pagePaddingH = 24.0;
  static const double pagePaddingHDesktop = 80.0;
  static const double sectionGapV = 80.0;
  static const double sectionGapVMobile = 56.0;
  // Platform-adaptive: 56px on native, 80px on web. Compile-time constant.
  static const double sectionGap = !kIsWeb ? sectionGapVMobile : sectionGapV;

  // Responsive breakpoints
  static const double mobileBreak  = 600.0;
  static const double tabletBreak  = 960.0;
  static const double desktopBreak = 1280.0;
}
