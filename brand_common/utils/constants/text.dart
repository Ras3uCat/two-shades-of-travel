import 'package:raspucat/utils/constants/brand.dart';

class EText {
  EText._();

  /// --- TO USE VARIABLES IN STRINGS --- ///
  /// --- '\$${EPricingCalculator.calculateTax(subTotal, 'US')}'--- ///
  /// --- '${EText.baseStorageErrorLoadingImage} $e' --- ///

  /// ------------------------------------------------------------------ ///

  /// --- APP TEXT --- ///
  ///
  ///
  static const String name = EBrand.appName;

  /// --- HERO SCREEN TEXT --- ///
  ///
  ///
  static const String heroHeading = EBrand.stylizedAppName;
  static const String heroSubtext = EBrand.voiceTagline;

  /// --- PROJECTS SCREEN TEXT --- ///
  ///
  ///
  static const String projectsHeading = 'Projects';
  static const String projectsSubheading = 'Explore my latest projects';
  static const String code = 'Code';
  static const String live = 'Live';
}
