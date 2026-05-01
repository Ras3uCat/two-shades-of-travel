import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_env.dart';
import 'e_colors.dart';
import 'personality_theme.dart';

/// ETextStyles — typography system driven by client.json fonts + personality.
/// All text in the app uses these styles — never raw TextStyle in widgets.
class ETextStyles {
  ETextStyles._();

  static TextStyle _primary({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    Color? color,
    double? height,
  }) {
    try {
      return GoogleFonts.getFont(
        AppEnv.fontPrimary,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color ?? EColors.onSurface,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color ?? EColors.onSurface,
        height: height,
      );
    }
  }

  static TextStyle _secondary({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    Color? color,
    double? height,
  }) {
    try {
      return GoogleFonts.getFont(
        AppEnv.fontSecondary,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color ?? EColors.onSurface,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color ?? EColors.onSurface,
        height: height,
      );
    }
  }

  static PersonalityTheme get _p => PersonalityTheme.fromEnv();

  // Scale factors for native mobile — kIsWeb is compile-time so these are too.
  // On native, large hero/display sizes are scaled down to app-appropriate sizes.
  // Body and UI text (≤18px) are not scaled — they are fine as-is on mobile.
  static const double _ds = kIsWeb ? 1.0 : 0.55; // display scale (72→40, 56→31, 40→22)
  static const double _hs = kIsWeb ? 1.0 : 0.82; // heading scale  (32→26, 24→20, 20→16)

  // ─── Display / Hero ───────────────────────────────────────────────────────
  static TextStyle get displayXL => _primary(
        size: 72 * _ds,
        weight: _p.headingWeight,
        letterSpacing: _p.headingLetterSpacing,
        height: 1.05,
      );

  static TextStyle get displayLg => _primary(
        size: 56 * _ds,
        weight: _p.headingWeight,
        letterSpacing: _p.headingLetterSpacing,
        height: 1.1,
      );

  static TextStyle get displayMd => _primary(
        size: 40 * _ds,
        weight: _p.headingWeight,
        letterSpacing: _p.headingLetterSpacing * 0.5,
        height: 1.15,
      );

  // ─── Headings ─────────────────────────────────────────────────────────────
  static TextStyle get h1 => _primary(
        size: 32 * _hs,
        weight: _p.headingWeight,
        letterSpacing: _p.headingLetterSpacing * 0.4,
        height: 1.2,
      );

  static TextStyle get h2 => _primary(
        size: 24 * _hs,
        weight: _p.headingWeight,
        height: 1.25,
      );

  static TextStyle get h3 => _secondary(
        size: 20 * _hs,
        weight: FontWeight.w600,
        height: 1.3,
      );

  // ─── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLg => _secondary(size: 18, height: 1.7);
  static TextStyle get body   => _secondary(size: 16, height: 1.65);
  static TextStyle get bodySm => _secondary(size: 14, height: 1.6);

  // ─── UI Elements ──────────────────────────────────────────────────────────
  static TextStyle get label    => _secondary(size: 14, weight: FontWeight.w500, letterSpacing: 0.5);
  static TextStyle get labelSm  => _secondary(size: 12, weight: FontWeight.w500, letterSpacing: 0.5);
  static TextStyle get caption  => _secondary(size: 12, color: EColors.onSurfaceMuted);
  static TextStyle get overline => _secondary(
        size: 11,
        weight: FontWeight.w600,
        letterSpacing: 2.0,
        color: EColors.primary,
      );

  static TextStyle get button => _secondary(
        size: 14,
        weight: FontWeight.w600,
        letterSpacing: 0.8,
      );

  static TextStyle get navItem => _secondary(
        size: 14,
        weight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  // ─── Muted variants ───────────────────────────────────────────────────────
  static TextStyle get bodyMuted   => body.copyWith(color: EColors.onSurfaceMuted);
  static TextStyle get bodySmMuted => bodySm.copyWith(color: EColors.onSurfaceMuted);

  // ─── Booking / domain-specific ────────────────────────────────────────────
  /// Sub-heading for card titles, artist names in overlays.
  static TextStyle get h4 => _secondary(size: 17, weight: FontWeight.w600, height: 1.3);

  /// Inline alias used in booking steps — equivalent to body.
  static TextStyle get bodyMd => body;

  /// Small tracking label for duration/time display (e.g. "45min", "→ 2:30 PM").
  static TextStyle get duration => _secondary(
        size: 11,
        weight: FontWeight.w500,
        letterSpacing: 1.2,
        color: EColors.onSurfaceMuted,
      );

  /// Price display — secondary font, bold, primary-colored.
  static TextStyle get price => _secondary(
        size: 20,
        weight: FontWeight.w700,
        color: EColors.primary,
      );

  /// Form field input text.
  static TextStyle get inputText => body;

  /// Form field label decoration.
  static TextStyle get inputLabel => label;
}
