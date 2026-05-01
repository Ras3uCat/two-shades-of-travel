part of 'personality_theme.dart';

// ─── EDGY — streetwear, tattoo studios, urban brands ─────────────────────────
final _edgy = PersonalityTheme._(
  cardRadius: 0,
  buttonRadius: 0,
  inputRadius: 0,
  animDuration: const Duration(milliseconds: 180),
  animCurve: Curves.easeInOut,
  heroTextAlign: TextAlign.left,
  heroContentMaxWidth: 900,
  sectionLayout: SectionLayout.fullWidth,
  navElevation: 0,
  navBackgroundOpacity: 1.0,
  headingWeight: FontWeight.w900,
  headingLetterSpacing: -1.0,
  useSerifPrimary: false,
  buttonStyle: ButtonStyleToken.solidSharp,
  cardStyle: CardStyleToken.colorBlock,
  dividerStyle: DividerStyleToken.diagonal,
);

// ─── PLAYFUL — kids' services, event venues, party planners ──────────────────
final _playful = PersonalityTheme._(
  cardRadius: 20,
  buttonRadius: 999,
  inputRadius: 16,
  animDuration: const Duration(milliseconds: 420),
  animCurve: Curves.elasticOut,
  heroTextAlign: TextAlign.center,
  heroContentMaxWidth: 680,
  sectionLayout: SectionLayout.centeredWide,
  navElevation: 2,
  navBackgroundOpacity: 1.0,
  headingWeight: FontWeight.w700,
  headingLetterSpacing: 0.5,
  useSerifPrimary: false,
  buttonStyle: ButtonStyleToken.pillSoft,
  cardStyle: CardStyleToken.softShadow,
  dividerStyle: DividerStyleToken.wave,
);

// ─── ARTISAN — cafes, bakeries, pottery, florists, independent bookshops ─────
final _artisan = PersonalityTheme._(
  cardRadius: 8,
  buttonRadius: 4,
  inputRadius: 4,
  animDuration: const Duration(milliseconds: 380),
  animCurve: Curves.easeInOut,
  heroTextAlign: TextAlign.left,
  heroContentMaxWidth: 640,
  sectionLayout: SectionLayout.leftAligned,
  navElevation: 0,
  navBackgroundOpacity: 1.0,
  headingWeight: FontWeight.w600,
  headingLetterSpacing: 0.5,
  useSerifPrimary: true,
  buttonStyle: ButtonStyleToken.outlined,
  cardStyle: CardStyleToken.bordered,
  dividerStyle: DividerStyleToken.wave,
);

// ─── WELLNESS — spas, yoga studios, meditation, holistic health ───────────────
final _wellness = PersonalityTheme._(
  cardRadius: 16,
  buttonRadius: 999,
  inputRadius: 12,
  animDuration: const Duration(milliseconds: 600),
  animCurve: Curves.easeInOut,
  heroTextAlign: TextAlign.center,
  heroContentMaxWidth: 640,
  sectionLayout: SectionLayout.centeredNarrow,
  navElevation: 0,
  navBackgroundOpacity: 0.0,
  headingWeight: FontWeight.w300,
  headingLetterSpacing: 2.0,
  useSerifPrimary: true,
  buttonStyle: ButtonStyleToken.pillSoft,
  cardStyle: CardStyleToken.floating,
  dividerStyle: DividerStyleToken.fullBleedImage,
);

// ─── TECH — SaaS, fintech, dev tools, agencies, software studios ──────────────
final _tech = PersonalityTheme._(
  cardRadius: 6,
  buttonRadius: 6,
  inputRadius: 6,
  animDuration: const Duration(milliseconds: 160),
  animCurve: Curves.easeOut,
  heroTextAlign: TextAlign.left,
  heroContentMaxWidth: 760,
  sectionLayout: SectionLayout.splitGrid,
  navElevation: 0,
  navBackgroundOpacity: 1.0,
  headingWeight: FontWeight.w700,
  headingLetterSpacing: -0.75,
  useSerifPrimary: false,
  buttonStyle: ButtonStyleToken.solidRounded,
  cardStyle: CardStyleToken.bordered,
  dividerStyle: DividerStyleToken.altBackground,
);

// ─── RETRO — vintage shops, classic barbershops, record stores, diners ────────
final _retro = PersonalityTheme._(
  cardRadius: 2,
  buttonRadius: 2,
  inputRadius: 2,
  animDuration: const Duration(milliseconds: 300),
  animCurve: Curves.easeInOut,
  heroTextAlign: TextAlign.center,
  heroContentMaxWidth: 700,
  sectionLayout: SectionLayout.centeredNarrow,
  navElevation: 4,
  navBackgroundOpacity: 1.0,
  headingWeight: FontWeight.w800,
  headingLetterSpacing: 2.5,
  useSerifPrimary: true,
  buttonStyle: ButtonStyleToken.solidSharp,
  cardStyle: CardStyleToken.bordered,
  dividerStyle: DividerStyleToken.thinRule,
);

// ─── NATURE — eco brands, organic food, outdoor gear, sustainability ──────────
final _nature = PersonalityTheme._(
  cardRadius: 12,
  buttonRadius: 8,
  inputRadius: 8,
  animDuration: const Duration(milliseconds: 450),
  animCurve: Curves.easeInOut,
  heroTextAlign: TextAlign.left,
  heroContentMaxWidth: 680,
  sectionLayout: SectionLayout.leftAligned,
  navElevation: 0,
  navBackgroundOpacity: 0.0,
  headingWeight: FontWeight.w600,
  headingLetterSpacing: 0.25,
  useSerifPrimary: true,
  buttonStyle: ButtonStyleToken.outlined,
  cardStyle: CardStyleToken.softShadow,
  dividerStyle: DividerStyleToken.fullBleedImage,
);

// ─── CREATIVE — photographers, designers, architects, artists ─────────────────
final _creative = PersonalityTheme._(
  cardRadius: 0,
  buttonRadius: 0,
  inputRadius: 0,
  animDuration: const Duration(milliseconds: 500),
  animCurve: Curves.easeInOut,
  heroTextAlign: TextAlign.left,
  heroContentMaxWidth: 1000,
  sectionLayout: SectionLayout.fullWidth,
  navElevation: 0,
  navBackgroundOpacity: 0.0,
  headingWeight: FontWeight.w300,
  headingLetterSpacing: 1.0,
  useSerifPrimary: false,
  buttonStyle: ButtonStyleToken.textWithArrow,
  cardStyle: CardStyleToken.flatFill,
  dividerStyle: DividerStyleToken.fullBleedImage,
);

// ─── NIGHTLIFE — restaurants, bars, clubs, cocktail lounges ──────────────────
final _nightlife = PersonalityTheme._(
  cardRadius: 4,
  buttonRadius: 4,
  inputRadius: 4,
  animDuration: const Duration(milliseconds: 550),
  animCurve: Curves.easeInOut,
  heroTextAlign: TextAlign.center,
  heroContentMaxWidth: 760,
  sectionLayout: SectionLayout.centeredWide,
  navElevation: 0,
  navBackgroundOpacity: 0.0,
  headingWeight: FontWeight.w300,
  headingLetterSpacing: 3.0,
  useSerifPrimary: true,
  buttonStyle: ButtonStyleToken.outlined,
  cardStyle: CardStyleToken.floating,
  dividerStyle: DividerStyleToken.fullBleedImage,
);
