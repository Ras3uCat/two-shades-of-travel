import 'package:raspucat/utils/constants/exports.dart';

class ETextTheme {
  ETextTheme._();

  // Noto Sans Japanese
  /// --- GOOGLE FONTS --- ///
  static final headerFont = GoogleFonts.notoSansJavanese;
  static final titleFont = GoogleFonts.roboto;
  static final bodyFont = GoogleFonts.roboto;

  static TextTheme lightTextTheme = TextTheme(
    /// --- HEADLINE TEXT --- ///
    headlineLarge: headerFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeHeadline * 2,
        fontWeight: FontWeight.bold,
        color: EColors.textPrimary,
      ),
    ),
    headlineMedium: headerFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeHeadline,
        fontWeight: FontWeight.bold,
        color: EColors.textPrimary,
      ),
    ),
    headlineSmall: headerFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeHeadline - 10,
        fontWeight: FontWeight.bold,
        color: EColors.textPrimary,
      ),
    ),

    /// --- TITLE TEXT --- ///
    titleLarge: titleFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeTitle + 10,
        fontWeight: FontWeight.w300,
        color: EColors.textPrimary,
      ),
    ),

    titleMedium: titleFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeTitle,
        fontWeight: FontWeight.w300,
        color: EColors.textPrimary,
      ),
    ),

    titleSmall: titleFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeTitle - 8,
        fontWeight: FontWeight.w300,
        color: EColors.textPrimary,
      ),
    ),

    /// --- BODY TEXT --- ///
    bodyLarge: bodyFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeBody + 4,
        fontWeight: FontWeight.w300,
        color: EColors.textPrimary,
      ),
    ),

    bodyMedium: bodyFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeBody,
        fontWeight: FontWeight.w300,
        color: EColors.textPrimary,
      ),
    ),

    bodySmall: bodyFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeBody - 4,
        fontWeight: FontWeight.w100,
        color: EColors.textPrimary,
      ),
    ),

    /// --- LABEL TEXT --- ///
    labelLarge: const TextStyle().copyWith(
      fontSize: ESizes.fontSizeLabel,
      fontWeight: FontWeight.normal,
      color: EColors.textPrimary,
    ),
    labelMedium: const TextStyle().copyWith(
      fontSize: ESizes.fontSizeLabel,
      fontWeight: FontWeight.normal,
      color: EColors.textPrimary.withOpacity(0.5),
    ),
  );

  static TextTheme darkTextTheme = TextTheme(
    /// --- HEADLINE TEXT --- ///
    headlineLarge: headerFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeHeadline * 2,
        fontWeight: FontWeight.bold,
        letterSpacing: 3,
        color: Color.lerp(EColors.textPrimary, EColors.textWhite, 0.6),
      ),
    ),
    headlineMedium: headerFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeHeadline,
        fontWeight: FontWeight.bold,
        color: EColors.textPrimary,
      ),
    ),
    headlineSmall: headerFont(
      textStyle: const TextStyle().copyWith(
        fontSize: ESizes.fontSizeHeadline - 10,
        fontWeight: FontWeight.bold,
        color: EColors.textPrimary,
      ),
    ),

    // Titles
    titleLarge: GoogleFonts.rubik(
      textStyle: const TextStyle().copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: EColors.textWhite,
      ),
    ),
    titleMedium: GoogleFonts.rubik(
      textStyle: const TextStyle().copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: EColors.textWhite,
      ),
    ),
    titleSmall: GoogleFonts.rubik(
      textStyle: const TextStyle().copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: EColors.textWhite,
      ),
    ),

    // Body
    bodyLarge: GoogleFonts.rubik(
      textStyle: const TextStyle().copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: EColors.textWhite,
      ),
    ),
    bodyMedium: GoogleFonts.rubik(
      textStyle: const TextStyle().copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: EColors.textWhite,
      ),
    ),
    bodySmall: GoogleFonts.rubik(
      textStyle: const TextStyle().copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: EColors.textWhite.withOpacity(0.5),
      ),
    ),

    // Label
    labelLarge: GoogleFonts.rubik(
      textStyle: const TextStyle().copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: EColors.textWhite,
      ),
    ),
    labelMedium: GoogleFonts.rubik(
      textStyle: const TextStyle().copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: EColors.textWhite.withOpacity(0.5),
      ),
    ),
  );
}


/// --- How to use:
/// --- style: Theme.of(context).textTheme.headlineMedium,
/// --- style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: EColors.accent),