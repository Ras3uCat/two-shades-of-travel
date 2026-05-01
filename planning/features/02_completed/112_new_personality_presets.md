# 112 — New Personality Presets & Hamburger Nav

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Complete

## Mode
FLOW

## Context
Feature 024 in Raspucat (Discovery Form) introduced `edgy` and `playful` as selectable
`PERSONALITY` values, and `hamburger` as a `NAV_STYLE` option. These values are already
written to `client.json` via the discovery form. modular_project must implement the
corresponding presets and nav shell before any client with these values goes live.

This feature also adds 7 further personality presets covering common client archetypes
currently missing from the system, bringing the total to 14.

Raspucat tracking: `raspucat/planning/features/00_backlog/027_new_personality_presets.md`

---

## 1. New Personalities — `personality_theme.dart`

**File:** `execution/frontend/app/lib/core/theme/personality_theme.dart`

Add to `_map` and define static presets. All field names must exactly match the
`PersonalityTheme._()` constructor.

---

### `edgy` — streetwear, tattoo studios, urban brands, nightlife
```dart
static final _edgy = PersonalityTheme._(
  cardRadius:            0,
  buttonRadius:          0,
  inputRadius:           0,
  animDuration:          const Duration(milliseconds: 180),
  animCurve:             Curves.easeInOut,
  heroTextAlign:         TextAlign.left,
  heroContentMaxWidth:   900,
  sectionLayout:         SectionLayout.fullWidth,
  navElevation:          0,
  navBackgroundOpacity:  1.0,
  headingWeight:         FontWeight.w900,
  headingLetterSpacing:  -1.0,
  useSerifPrimary:       false,
  buttonStyle:           ButtonStyleToken.solidSharp,
  cardStyle:             CardStyleToken.colorBlock,
  dividerStyle:          DividerStyleToken.diagonal,
);
```

---

### `playful` — kids' services, event venues, party planners, entertainment
```dart
static final _playful = PersonalityTheme._(
  cardRadius:            20,
  buttonRadius:          999,
  inputRadius:           16,
  animDuration:          const Duration(milliseconds: 420),
  animCurve:             Curves.elasticOut,
  heroTextAlign:         TextAlign.center,
  heroContentMaxWidth:   680,
  sectionLayout:         SectionLayout.centeredWide,
  navElevation:          2,
  navBackgroundOpacity:  1.0,
  headingWeight:         FontWeight.w700,
  headingLetterSpacing:  0.5,
  useSerifPrimary:       false,
  buttonStyle:           ButtonStyleToken.pillSoft,
  cardStyle:             CardStyleToken.softShadow,
  dividerStyle:          DividerStyleToken.wave,
);
```

---

### `artisan` — cafes, bakeries, pottery, florists, independent bookshops
```dart
static final _artisan = PersonalityTheme._(
  cardRadius:            8,
  buttonRadius:          4,
  inputRadius:           4,
  animDuration:          const Duration(milliseconds: 380),
  animCurve:             Curves.easeInOut,
  heroTextAlign:         TextAlign.left,
  heroContentMaxWidth:   640,
  sectionLayout:         SectionLayout.leftAligned,
  navElevation:          0,
  navBackgroundOpacity:  1.0,
  headingWeight:         FontWeight.w600,
  headingLetterSpacing:  0.5,
  useSerifPrimary:       true,
  buttonStyle:           ButtonStyleToken.outlined,
  cardStyle:             CardStyleToken.bordered,
  dividerStyle:          DividerStyleToken.wave,
);
```

---

### `wellness` — spas, yoga studios, meditation, holistic health, beauty
```dart
static final _wellness = PersonalityTheme._(
  cardRadius:            16,
  buttonRadius:          999,
  inputRadius:           12,
  animDuration:          const Duration(milliseconds: 600),
  animCurve:             Curves.easeInOut,
  heroTextAlign:         TextAlign.center,
  heroContentMaxWidth:   640,
  sectionLayout:         SectionLayout.centeredNarrow,
  navElevation:          0,
  navBackgroundOpacity:  0.0,
  headingWeight:         FontWeight.w300,
  headingLetterSpacing:  2.0,
  useSerifPrimary:       true,
  buttonStyle:           ButtonStyleToken.pillSoft,
  cardStyle:             CardStyleToken.floating,
  dividerStyle:          DividerStyleToken.fullBleedImage,
);
```

---

### `tech` — SaaS, fintech, dev tools, agencies, software studios
```dart
static final _tech = PersonalityTheme._(
  cardRadius:            6,
  buttonRadius:          6,
  inputRadius:           6,
  animDuration:          const Duration(milliseconds: 160),
  animCurve:             Curves.easeOut,
  heroTextAlign:         TextAlign.left,
  heroContentMaxWidth:   760,
  sectionLayout:         SectionLayout.splitGrid,
  navElevation:          0,
  navBackgroundOpacity:  1.0,
  headingWeight:         FontWeight.w700,
  headingLetterSpacing:  -0.75,
  useSerifPrimary:       false,
  buttonStyle:           ButtonStyleToken.solidRounded,
  cardStyle:             CardStyleToken.bordered,
  dividerStyle:          DividerStyleToken.altBackground,
);
```

---

### `retro` — vintage shops, classic barbershops, record stores, diners, antiques
```dart
static final _retro = PersonalityTheme._(
  cardRadius:            2,
  buttonRadius:          2,
  inputRadius:           2,
  animDuration:          const Duration(milliseconds: 300),
  animCurve:             Curves.easeInOut,
  heroTextAlign:         TextAlign.center,
  heroContentMaxWidth:   700,
  sectionLayout:         SectionLayout.centeredNarrow,
  navElevation:          4,
  navBackgroundOpacity:  1.0,
  headingWeight:         FontWeight.w800,
  headingLetterSpacing:  2.5,
  useSerifPrimary:       true,
  buttonStyle:           ButtonStyleToken.solidSharp,
  cardStyle:             CardStyleToken.bordered,
  dividerStyle:          DividerStyleToken.thinRule,
);
```

---

### `nature` — eco brands, organic food, outdoor gear, sustainability, farming
```dart
static final _nature = PersonalityTheme._(
  cardRadius:            12,
  buttonRadius:          8,
  inputRadius:           8,
  animDuration:          const Duration(milliseconds: 450),
  animCurve:             Curves.easeInOut,
  heroTextAlign:         TextAlign.left,
  heroContentMaxWidth:   680,
  sectionLayout:         SectionLayout.leftAligned,
  navElevation:          0,
  navBackgroundOpacity:  0.0,
  headingWeight:         FontWeight.w600,
  headingLetterSpacing:  0.25,
  useSerifPrimary:       true,
  buttonStyle:           ButtonStyleToken.outlined,
  cardStyle:             CardStyleToken.softShadow,
  dividerStyle:          DividerStyleToken.fullBleedImage,
);
```

---

### `creative` — photographers, designers, architects, artists, studios
```dart
static final _creative = PersonalityTheme._(
  cardRadius:            0,
  buttonRadius:          0,
  inputRadius:           0,
  animDuration:          const Duration(milliseconds: 500),
  animCurve:             Curves.easeInOut,
  heroTextAlign:         TextAlign.left,
  heroContentMaxWidth:   1000,
  sectionLayout:         SectionLayout.fullWidth,
  navElevation:          0,
  navBackgroundOpacity:  0.0,
  headingWeight:         FontWeight.w300,
  headingLetterSpacing:  1.0,
  useSerifPrimary:       false,
  buttonStyle:           ButtonStyleToken.textWithArrow,
  cardStyle:             CardStyleToken.flatFill,
  dividerStyle:          DividerStyleToken.fullBleedImage,
);
```

---

### `nightlife` — restaurants, bars, clubs, cocktail lounges, live music venues
```dart
static final _nightlife = PersonalityTheme._(
  cardRadius:            4,
  buttonRadius:          4,
  inputRadius:           4,
  animDuration:          const Duration(milliseconds: 550),
  animCurve:             Curves.easeInOut,
  heroTextAlign:         TextAlign.center,
  heroContentMaxWidth:   760,
  sectionLayout:         SectionLayout.centeredWide,
  navElevation:          0,
  navBackgroundOpacity:  0.0,
  headingWeight:         FontWeight.w300,
  headingLetterSpacing:  3.0,
  useSerifPrimary:       true,
  buttonStyle:           ButtonStyleToken.outlined,
  cardStyle:             CardStyleToken.floating,
  dividerStyle:          DividerStyleToken.fullBleedImage,
);
```

---

### Updated `_map` (14 personalities)
```dart
static final Map<String, PersonalityTheme> _map = {
  'luxury':    _luxury,
  'minimal':   _minimal,
  'bold':      _bold,
  'warm':      _warm,
  'corporate': _corporate,
  'edgy':      _edgy,
  'playful':   _playful,
  'artisan':   _artisan,
  'wellness':  _wellness,
  'tech':      _tech,
  'retro':     _retro,
  'nature':    _nature,
  'creative':  _creative,
  'nightlife': _nightlife,
};
```

**File size check:** currently 175 lines + ~9 presets × 20 lines = ~355 lines — OVER 300.
Extract the 9 new presets to `_personality_presets.dart` (private file, part of same library)
and keep `personality_theme.dart` to class definition + `_map` + original 5 presets only.

---

## 2. Hamburger Nav — `app_shell.dart` only

`_MobileShell` already implements exactly what hamburger nav is: a top `AppBar` with
Flutter's built-in drawer hamburger icon + `_NavDrawer()`. Reuse it for all viewports
when `NAV_STYLE: hamburger` is set — no new widget needed.

### `app_shell.dart` change (one line)
**File:** `execution/frontend/app/lib/core/widgets/app_shell.dart`

```dart
return switch (AppEnv.navStyle) {
  'sidebar'    => _SidebarShell(child: child),
  'minimal'    => _MinimalShell(child: child),
  'hamburger'  => _MobileShell(child: child),   // reuse — drawer on all viewports
  _            => _TopBarShell(child: child),
};
```

No new files. No new widget. `app_shell.dart` stays well under 300 lines.

---

## Acceptance Criteria
- [ ] All 5 original personalities show no regression (`luxury`, `bold`, `warm`, `minimal`, `corporate`)
- [ ] `PERSONALITY: edgy` — sharp corners, heavy weight, full-width, fast
- [ ] `PERSONALITY: playful` — pill buttons, bouncy elastic, rounded cards
- [ ] `PERSONALITY: artisan` — serif, bordered cards, left-aligned, moderate pace
- [ ] `PERSONALITY: wellness` — overlay nav, slow calm animation, narrow centered
- [ ] `PERSONALITY: tech` — split grid, crisp motion, tight letter spacing
- [ ] `PERSONALITY: retro` — serif, wide letter spacing, near-flat corners, thin rules
- [ ] `PERSONALITY: nature` — overlay nav, serif, organic radius, fullbleed dividers
- [ ] `PERSONALITY: creative` — fullbleed, transparent nav, text-with-arrow buttons, editorial
- [ ] `PERSONALITY: nightlife` — transparent nav, wide letter spacing, serif, slow moody animation
- [ ] Unknown `PERSONALITY` falls back to `minimal`
- [ ] `NAV_STYLE: hamburger` — drawer nav on all viewport sizes (mobile + desktop)
- [ ] `personality_theme.dart` stays under 300 lines (extract new presets to `_personality_presets.dart`)
- [ ] `app_shell.dart` stays under 300 lines (no new widget added)
- [ ] `flutter analyze` — zero issues

## Scope (files to create/modify)
- `execution/frontend/app/lib/core/theme/personality_theme.dart` — add `_map` entries, import presets file
- `execution/frontend/app/lib/core/theme/_personality_presets.dart` — new file, 9 new preset definitions
- `execution/frontend/app/lib/core/widgets/app_shell.dart` — add `hamburger` case (one line)

## Dependencies
- No migration required
- No new packages required
- Update Raspucat 024 discovery form personality dropdown to include all 9 new values when this ships
- Update Raspucat 027 to reflect final personality list

## Fallbacks Until This Ships
| Personality | Fallback |
|-------------|---------|
| edgy        | minimal   |
| playful     | warm      |
| artisan     | warm      |
| wellness    | luxury    |
| tech        | corporate |
| retro       | corporate |
| nature      | warm      |
| creative    | minimal   |
| nightlife   | luxury    |
| hamburger nav | topbar (default) |
