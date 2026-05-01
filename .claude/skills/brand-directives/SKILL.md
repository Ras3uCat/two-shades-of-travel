# Skill: Brand Directives (Inspiration → Flutter)

## Purpose
Translate the Brand Alignment Report (`planning/client/brand_alignment.md`) into concrete
Flutter implementation directives. Loaded alongside `flutter_dev` when building a client site.
Ensures that what the client showed you in inspiration URLs actually shapes the code AntiGravity writes.

## When to Load
- Any time you are building or scaffolding Flutter UI for a client
- When `planning/client/brand_alignment.md` exists in the project

## On Load: Read and Apply

1. Read `planning/client/brand_alignment.md`
2. Read `execution/frontend/app/client.json` — extract: PERSONALITY, HOME_SECTIONS, MODULES, BRAND_THREE_WORDS, BRAND_CELEBRITY, BRAND_TARGET_CUSTOMER
3. Derive and hold the following **Active Directives** for the session:

---

## Directive Mapping

### From Section A — Visual Brand
- Lock `PERSONALITY` to the recommended value (or confirmed value if already aligned)
- Use recommended hex values when setting `EColors` constants — do not deviate
- Use recommended Google Fonts names for `FONT_PRIMARY` / `FONT_SECONDARY`
- Apply `HERO_VARIANT` to the hero widget implementation

### From Section B — Layout Patterns
- Use the recommended `HOME_SECTIONS` order as the scroll sequence in `HomeView`
- Match grid density: sparse = generous `ESpacing` values, dense = tighter padding, more content per viewport
- Replicate above-the-fold pattern: if all inspiration sites show [hero + single CTA], do not stack multiple modules above the fold
- Apply identified structural motifs:
  - Sticky nav → `SliverAppBar` with `pinned: true`
  - Full-bleed images → `BoxFit.cover` with no horizontal padding, edge-to-edge
  - Card grids → `GridView` or `Wrap` with consistent `ESpacing.md` gaps

### From Section C — Interactive Elements
Map detected animation libraries/patterns to Flutter equivalents:

| Inspiration signal | Flutter implementation |
|--------------------|----------------------|
| AOS fade-in on scroll | `AnimatedOpacity` + `VisibilityDetector` |
| GSAP scroll-driven | `ScrollController` + `AnimatedBuilder` |
| Lottie animations | `lottie` package + `.json` asset |
| Parallax hero | `CustomScrollView` + `SliverToBoxAdapter` offset |
| Button lift / hover | `AnimatedScale` on `onHover` (web) / `InkWell` ripple (mobile) |
| Image zoom on hover | `MouseRegion` + `AnimatedScale` |
| Carousel | `PageView` + dot indicators |
| Accordion / expand | `ExpansionTile` |
| Modal / bottom sheet | `showModalBottomSheet` |

Use `const` durations: subtle = `Duration(milliseconds: 200)`, standard = `Duration(milliseconds: 350)`, dramatic = `Duration(milliseconds: 600)`.

### From Section D — Guest Flow
- Map the conversion path to the screen/widget sequence in `HOME_SECTIONS`
- Place the primary CTA widget at the position the inspiration sites establish trust (after testimonials, after service list — wherever trust signals appeared before the CTA)
- If inspiration sites used inline booking (no redirect), use the in-page `BookingWidget` — do not route away from home
- If inspiration sites used guest checkout (no login required), ensure `AUTH_REQUIRED` is not gating the booking entry point
- Replicate trust signals before CTA: if testimonials appeared before the booking CTA across all sites, `testimonials` section must precede `cta` in `HOME_SECTIONS`

### From Section E — Conflicts & Gaps
- For every flagged conflict: explicitly note it in a code comment at the relevant widget (`// NOTE: client.json says luxury but inspiration signals minimal — using minimal spacing here per BAR`)
- For every flagged gap (module not selected but prominent in inspiration): do not add the module, but surface the gap to the developer as a comment in the relevant section widget

---

### From BRAND_THREE_WORDS
Map the three words to animation and typography decisions:

| Word signals | Animation duration | Font weight | Corner radius | Shadow |
|---|---|---|---|---|
| bold / punchy / strong | 150–250ms | w700–w900 | sharp (0–4px) | none or hard |
| calm / clean / minimal | 400–600ms | w300–w400 | medium (8–12px) | none |
| warm / friendly / cozy | 300–400ms | w400–w500 | large (16–24px) | soft, diffuse |
| luxury / elegant / refined | 500–700ms | w300 (light headings) | subtle (4–8px) | none |
| playful / fun / vibrant | 200–350ms | w600–w700 | large (20px+) | colorful/tinted |

If words conflict (e.g. "bold, minimal, warm"), the first word wins for motion; the third word wins for color temperature.

### From BRAND_CELEBRITY
Use as a visual energy reference for the overall Flutter design system:

| Celebrity archetype | Energy level | Flutter directives |
|---|---|---|
| High-energy performer (Beyoncé, Rihanna, Drake) | Dramatic | Transitions 500–700ms, `Curves.easeInOutCubic`, saturated `EColors.accent`, heavy type scale |
| Refined / editorial (Anna Wintour, Steve Jobs, Audrey Hepburn) | Restrained | Transitions 150–250ms, `Curves.easeOut`, muted palette, thin weight headings, whitespace-heavy |
| Approachable / media (Oprah, Ellen, Jamie Oliver) | Warm | Transitions 300ms, `Curves.easeInOut`, warm accent colors, rounded UI, conversational copy |
| Athletic / performance (Nike, Serena Williams) | Kinetic | Transitions 200ms, `Curves.easeIn`, high contrast, bold CTAs, minimal copy |
| Corporate / authoritative (Barack Obama, Warren Buffett) | Measured | Transitions 250ms, `Curves.linear`, navy/grey palette, structured grid, no decorative elements |

If BRAND_CELEBRITY doesn't match a known archetype, infer from the BAR's Section A personality and BRAND_THREE_WORDS.

### From BRAND_TARGET_CUSTOMER
Shape UX decisions around who is actually using the site:

- **Age 18–30:** Larger tap targets (48px+), bottom-nav preferred on mobile, short copy, emoji-safe copy tone
- **Age 30–50, professional:** Inline booking flow (no redirects), minimal account creation friction, trust signals before CTA (credentials, press, reviews count)
- **Age 50+:** Minimum 16px body text, high contrast, fewer steps per screen, phone number prominently placed
- **Luxury buyer:** Longer scroll journey acceptable, quality signals (material metaphors, slow reveals), price presented late in the flow
- **Budget-conscious:** Price/value visible immediately, clear comparison, fast CTA access
- **Local community:** Social proof with faces/names (not generic stars), map/location prominent, "about us" weighted highly in HOME_SECTIONS

---

## Enforcement Rules
- **Never** use raw spacing/color values — all values flow through `EColors` / `ESpacing` derived from client.json
- **Never** override `HOME_SECTIONS` order without a BAR-backed reason
- **Never** introduce an animation pattern not in the BAR mapping above without flagging it
- If `brand_alignment.md` is missing: warn the developer to run `/inspo` first, then proceed with client.json values only
