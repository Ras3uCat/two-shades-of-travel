import 'package:flutter/material.dart';
import '../config/app_env.dart';

part '_personality_presets.dart';

/// PersonalityTheme — layout, motion, and shape constants driven by personality.
/// Every module widget reads from this — never hardcode radii, durations, or
/// layout constants directly.
class PersonalityTheme {
  PersonalityTheme._({
    required this.cardRadius,
    required this.buttonRadius,
    required this.inputRadius,
    required this.animDuration,
    required this.animCurve,
    required this.heroTextAlign,
    required this.heroContentMaxWidth,
    required this.sectionLayout,
    required this.navElevation,
    required this.navBackgroundOpacity,
    required this.headingWeight,
    required this.headingLetterSpacing,
    required this.useSerifPrimary,
    required this.buttonStyle,
    required this.cardStyle,
    required this.dividerStyle,
  });

  // Shape
  final double cardRadius;
  final double buttonRadius;
  final double inputRadius;

  // Motion
  final Duration animDuration;
  final Curve animCurve;

  // Layout
  final TextAlign heroTextAlign;
  final double heroContentMaxWidth;
  final SectionLayout sectionLayout;

  // Nav
  final double navElevation;
  final double navBackgroundOpacity;

  // Typography modifiers
  final FontWeight headingWeight;
  final double headingLetterSpacing;
  final bool useSerifPrimary;

  // Style tokens
  final ButtonStyleToken buttonStyle;
  final CardStyleToken cardStyle;
  final DividerStyleToken dividerStyle;

  // ─── Factory ─────────────────────────────────────────────────────────────
  static PersonalityTheme fromEnv() => _map[AppEnv.personality] ?? _minimal;

  static final Map<String, PersonalityTheme> _map = {
    'luxury': _luxury,
    'minimal': _minimal,
    'bold': _bold,
    'warm': _warm,
    'corporate': _corporate,
    'edgy': _edgy,
    'playful': _playful,
    'artisan': _artisan,
    'wellness': _wellness,
    'tech': _tech,
    'retro': _retro,
    'nature': _nature,
    'creative': _creative,
    'nightlife': _nightlife,
  };

  // ─── LUXURY ──────────────────────────────────────────────────────────────
  static final _luxury = PersonalityTheme._(
    cardRadius: 0,
    buttonRadius: 999,
    inputRadius: 0,
    animDuration: const Duration(milliseconds: 650),
    animCurve: Curves.easeInOut,
    heroTextAlign: TextAlign.center,
    heroContentMaxWidth: 720,
    sectionLayout: SectionLayout.centeredNarrow,
    navElevation: 0,
    navBackgroundOpacity: 0.0,
    headingWeight: FontWeight.w300,
    headingLetterSpacing: 4.0,
    useSerifPrimary: true,
    buttonStyle: ButtonStyleToken.outlined,
    cardStyle: CardStyleToken.floating,
    dividerStyle: DividerStyleToken.fullBleedImage,
  );

  // ─── MINIMAL ─────────────────────────────────────────────────────────────
  static final _minimal = PersonalityTheme._(
    cardRadius: 4,
    buttonRadius: 4,
    inputRadius: 4,
    animDuration: const Duration(milliseconds: 180),
    animCurve: Curves.easeOut,
    heroTextAlign: TextAlign.left,
    heroContentMaxWidth: 600,
    sectionLayout: SectionLayout.leftAligned,
    navElevation: 0,
    navBackgroundOpacity: 1.0,
    headingWeight: FontWeight.w500,
    headingLetterSpacing: -0.5,
    useSerifPrimary: false,
    buttonStyle: ButtonStyleToken.textWithArrow,
    cardStyle: CardStyleToken.flatFill,
    dividerStyle: DividerStyleToken.thinRule,
  );

  // ─── BOLD ─────────────────────────────────────────────────────────────────
  static final _bold = PersonalityTheme._(
    cardRadius: 0,
    buttonRadius: 0,
    inputRadius: 0,
    animDuration: const Duration(milliseconds: 220),
    animCurve: Curves.easeInCubic,
    heroTextAlign: TextAlign.left,
    heroContentMaxWidth: 800,
    sectionLayout: SectionLayout.fullWidth,
    navElevation: 4,
    navBackgroundOpacity: 1.0,
    headingWeight: FontWeight.w900,
    headingLetterSpacing: -1.5,
    useSerifPrimary: false,
    buttonStyle: ButtonStyleToken.solidSharp,
    cardStyle: CardStyleToken.colorBlock,
    dividerStyle: DividerStyleToken.diagonal,
  );

  // ─── WARM ─────────────────────────────────────────────────────────────────
  static final _warm = PersonalityTheme._(
    cardRadius: 24,
    buttonRadius: 999,
    inputRadius: 16,
    animDuration: const Duration(milliseconds: 500),
    animCurve: Curves.elasticOut,
    heroTextAlign: TextAlign.center,
    heroContentMaxWidth: 680,
    sectionLayout: SectionLayout.centeredWide,
    navElevation: 2,
    navBackgroundOpacity: 1.0,
    headingWeight: FontWeight.w600,
    headingLetterSpacing: 0.0,
    useSerifPrimary: false,
    buttonStyle: ButtonStyleToken.pillSoft,
    cardStyle: CardStyleToken.softShadow,
    dividerStyle: DividerStyleToken.wave,
  );

  // ─── CORPORATE ───────────────────────────────────────────────────────────
  static final _corporate = PersonalityTheme._(
    cardRadius: 8,
    buttonRadius: 8,
    inputRadius: 8,
    animDuration: const Duration(milliseconds: 200),
    animCurve: Curves.easeInOut,
    heroTextAlign: TextAlign.left,
    heroContentMaxWidth: 560,
    sectionLayout: SectionLayout.splitGrid,
    navElevation: 1,
    navBackgroundOpacity: 1.0,
    headingWeight: FontWeight.w600,
    headingLetterSpacing: -0.25,
    useSerifPrimary: false,
    buttonStyle: ButtonStyleToken.solidRounded,
    cardStyle: CardStyleToken.bordered,
    dividerStyle: DividerStyleToken.altBackground,
  );
}

// ─── Style Token Enums ───────────────────────────────────────────────────────

enum SectionLayout { centeredNarrow, centeredWide, leftAligned, fullWidth, splitGrid }

enum ButtonStyleToken { outlined, textWithArrow, solidSharp, pillSoft, solidRounded }

enum CardStyleToken { floating, flatFill, colorBlock, softShadow, bordered }

enum DividerStyleToken { fullBleedImage, thinRule, diagonal, wave, altBackground }
