import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_env.dart';
import 'e_colors.dart';
import 'e_text_styles.dart';
import 'personality_theme.dart';

/// ThemeFactory — assembles a full Material 3 ThemeData from client.json values.
/// Called once in main.dart. Everything downstream uses the theme or E-prefix constants.
class ThemeFactory {
  ThemeFactory._();

  static ThemeData fromEnv() {
    final pt = PersonalityTheme.fromEnv();

    final colorScheme = ColorScheme(
      brightness: _brightness(),
      primary:          EColors.primary,
      onPrimary:        _contrastFor(EColors.primary),
      secondary:        EColors.secondary,
      onSecondary:      _contrastFor(EColors.secondary),
      tertiary:         EColors.accent,
      onTertiary:       _contrastFor(EColors.accent),
      surface:          EColors.surface,
      onSurface:        EColors.onSurface,
      error:            EColors.error,
      onError:          Colors.white,
      surfaceContainerHighest: EColors.surfaceVariant,
      outline:          EColors.divider,
    );

    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.getTextTheme(AppEnv.fontSecondary).apply(
        bodyColor: EColors.onSurface,
        displayColor: EColors.onSurface,
      );
    } catch (_) {
      textTheme = ThemeData.light().textTheme;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: EColors.surface,

      // Cards
      cardTheme: CardThemeData(
        elevation: pt.cardStyle == CardStyleToken.softShadow ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pt.cardRadius),
          side: pt.cardStyle == CardStyleToken.bordered
              ? BorderSide(color: EColors.divider)
              : BorderSide.none,
        ),
        color: pt.cardStyle == CardStyleToken.flatFill
            ? EColors.surfaceVariant
            : EColors.surface,
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EColors.primary,
          foregroundColor: _contrastFor(EColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pt.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 0,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EColors.primary,
          side: BorderSide(color: EColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pt.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pt.buttonRadius),
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pt.inputRadius),
          borderSide: BorderSide(color: EColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pt.inputRadius),
          borderSide: BorderSide(color: EColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pt.inputRadius),
          borderSide: BorderSide(color: EColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: EColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: EColors.surface.withValues(alpha: pt.navBackgroundOpacity),
        elevation: pt.navElevation,
        scrolledUnderElevation: pt.navElevation,
        foregroundColor: EColors.onSurface,
        centerTitle: pt.heroTextAlign == TextAlign.center,
      ),

      // NavigationBar (native mobile bottom nav)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: EColors.surface,
        indicatorColor: EColors.primaryLight,
        labelTextStyle: WidgetStateProperty.all(ETextStyles.labelSm),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: EColors.divider,
        thickness: 1,
        space: 0,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux:   FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS:   FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static Brightness _brightness() {
    final surface = EColors.surface;
    final luminance = surface.computeLuminance();
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }

  static Color _contrastFor(Color bg) {
    return bg.computeLuminance() > 0.4 ? Colors.black : Colors.white;
  }
}
