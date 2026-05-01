import 'package:raspucat/utils/constants/exports.dart';

class EColors {
  EColors._();

  // ------------------------------------------------------------------ //
  // BRAND PALETTE (Ras3uCat Identity System v1.0)
  //
  // P-Cyan     #58E3EF — primary actions, outlines, focus
  // A-Magenta  #D34CF1 — hover, highlights, energy states
  // Midnight   #000612 — deep background
  // C-Slate    #1A1C2C — cards, panels, containers
  // M3OW-Gold  #FFB938 — sigil text, emphasis, badges
  // ------------------------------------------------------------------ //

  /// --- App Basic Colors --- ///
  ///
  ///
  static const Color primary = Color(0xFF58E3EF); // P-Cyan
  static const Color secondary = Color(0xFFD9BDAD);
  static const Color tertiary = Color(0xFF607D8B);
  static const Color accent = Color(0xFFD34CF1); // A-Magenta
  static const Color gold = Color(0xFFFFB938); // M3OW-Gold — sigil & badges
  static const Color circuitSlate = Color(0xFF1A1C2C); // surface containers

  /// --- Background Colors --- ///
  ///
  ///
  static const Color backgroundLight = EColors.white;
  static const Color backgroundDark = Color(0xFF000612); // Midnight-Base
  // Brand rule: never use pure white as text — use this cyan-tinted white instead
  static const Color cyanTintedWhite = Color(0xFFE8FEFF);

  /// --- Gradient Colors --- ///
  ///
  ///
  static const Gradient linearGradient = LinearGradient(
    begin: Alignment(0, 0),
    colors: [
      Color.fromARGB(255, 12, 117, 124),
      Color.fromARGB(255, 95, 36, 172),
      Color.fromARGB(255, 0, 195, 255),
    ],
  );

  /// --- COLOR LIST --- ///
  ///
  ///
  static const List<Color> colors = [
    Color(0x334FC3F7), // Faint blue (20% opacity)
    Color(0x3329B6F6), // Faint indigo (20% opacity)
    Color(0x3303DAC6), // Faint teal (20% opacity)
    Color(0x3300BCD4), // Faint cyan (20% opacity)
    Color(0x332196F3), // Faint blue (20% opacity)
    Color(0x333F51B5), // Faint indigo (20% opacity)
    Color(0x33009888), // Faint teal (20% opacity)
    Color(0x3300ACC1), // Faint cyan (20% opacity)
    Color(0x330288D1), // Faint blue (20% opacity)
    Color(0x331976D2), // Faint blue (20% opacity)
  ];

  /// --- Text Colors --- ///
  ///
  ///
  static const Color textPrimary = primary;
  static const Color textSecondary = tertiary;
  static const Color textWhite = backgroundLight;

  /// --- Background Container Colors --- ///
  ///
  ///
  static const Color containerLight = secondary;
  static const Color containerDark = tertiary;

  /// --- Button Colors --- ///
  ///
  ///
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonDisabled = backgroundDark;

  /// --- Border Colors --- ///
  ///
  ///
  static const Color borderPrimary = primary;
  static const Color borderSecondary = secondary;

  /// --- Shimmer Colors --- ///
  ///
  ///
  static const Color shimmerBaseDark = backgroundDark;
  static const Color shimmerBaseLight = backgroundLight;
  static const Color shimmerHighlightDark = tertiary;
  static const Color shimmerHighlightLight = secondary;
  static const Color shimmerBorderDark = backgroundLight;
  static const Color shimmerBorderLight = backgroundDark;

  // Error and Validation Colors
  static const Color error = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.yellow;
  static const Color info = Color(0xFF4B68FF);

  // Neutral Shades
  static const Color black = Colors.black;
  static const Color darkGrey = Colors.grey;
  static const Color grey = Colors.blueGrey;
  static const Color softGrey = Color(0xFF9E9E9E);
  static const Color white = Colors.white;

  /// --- Product Colors --- ///
  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color blue = Colors.blue;
}
