# Frontend Design — Detailed Implementation Guide

---

## PROJECT WIDGET CATALOG — Check This Before Building Anything

**Rule**: Before writing a single animation widget from scratch, search this table. If the need is covered, import the existing widget. Do not rebuild what already exists.

| Design Need | Widget | File (relative to `lib/`) | Notes |
|---|---|---|---|
| Branded cursor (web) | `CursorOverlay` | `core/widgets/cursor_overlay.dart` | Already at root in `main.dart` — no re-wiring needed |
| Magnetic CTA / nav hover | `MagneticWidget` | `core/widgets/magnetic_widget.dart` | Wrap `ElevatedButton`, `TextButton`, nav icons |
| 3D perspective card hover | `TiltCard` | `core/widgets/tilt_card.dart` | Wrap any card; `maxAngleDeg` default 8° |
| Scroll-triggered section reveal | `RevealOnScroll` | `core/widgets/reveal_on_scroll.dart` | `delay:` for stagger; fires once at 20% visibility |
| Word/character headline entrance | `TextReveal` | `core/widgets/text_reveal.dart` | `trigger: bool`; mode `word` (default) or `character` |
| Drag carousel with spring decay | `InertiaCarousel` | `core/widgets/inertia_carousel.dart` | `itemWidth` required |
| Hero ambient background | `AmbientHeroBackground` | `core/widgets/ambient_hero_background.dart` | Slow gradient drift + noise; use as first Stack child in hero |
| Section divider | `SectionDivider` | `core/widgets/section_divider.dart` | Gold hairline + diamond ornament; replaces plain `Divider()` between sections |
| Shimmer image placeholder | `ShimmerPlaceholder` | `core/widgets/shimmer_placeholder.dart` | `slot:` param for `/image-gen` targeting |
| Page enter loader + curtain | `AppLoader` | `core/widgets/app_loader.dart` | Already wired in `main.dart`; ring animation + curtain reveal |
| Scrolling text strip | `MarqueeSection` | `core/widgets/marquee_section.dart` | Use between hero and first content section |
| Cheese wheel hero element | `WheelLayer` | `modules/home/views/hero/_wheel_layer.dart` | Cheese-specific; port the rotation+tilt pattern for other brands |

---

## PREMIUM DESIGN CHECKLIST — Run Before Marking Any Screen Complete

**Every screen, every section, every feature. No exceptions.**

### Motion
- [ ] Sections entering the viewport use `RevealOnScroll` with staggered `delay:` values (50ms increments)
- [ ] Hero headline uses `TextReveal` (word mode for long copy, character mode for short punchy copy)
- [ ] Primary CTA button is wrapped in `MagneticWidget`
- [ ] Content cards (service, product, portfolio) are wrapped in `TiltCard`
- [ ] Carousels and horizontal scroll sections use `InertiaCarousel`
- [ ] Hero section has `AmbientHeroBackground` as the first `Stack` child

### Typography
- [ ] All section overlines/eyebrows use `ETextStyles.eyebrow` (JetBrains Mono, tracked) — **never** raw `overline` style
- [ ] Hero headline on editorial/artisan builds: `ETextStyles.displaySerif` (Playfair Display 900 italic)
- [ ] Catalogue numbers use `ETextStyles.svcNum`; catalogue tags use `ETextStyles.svcTag`
- [ ] No raw `TextStyle(...)` anywhere in widget files — use `ETextStyles.*` only

### Color
- [ ] No raw hex values in widget files — use `EColors.*`
- [ ] Muted secondary labels use `EColors.onSurfaceDim` (not `onSurfaceMuted` which is 50% opacity)
- [ ] No `.withOpacity()` — use `.withValues(alpha:)` throughout

### Structure
- [ ] Between home sections: `SectionDivider` not `Divider()`
- [ ] All files ≤ 300 lines; extract at 250
- [ ] `flutter analyze` returns zero errors

---

## COLOR ROLE QUICK REFERENCE

```
EColors.surface          #0D0907  page background (near-black)
EColors.primary          #FF4500  orange — CTAs, price, accent pill
EColors.secondary        #D4A853  gold — dividers, ornaments, line-art illustrations
EColors.accent           #E8650A  warm orange — specks, highlights, hover states
EColors.onSurface        #F0E6D0  parchment cream — primary body text
EColors.onSurfaceDim     #A89B80  warm taupe — eyebrow labels, tags, secondary text
EColors.onSurfaceMuted              onSurface at 0.5 — captions, placeholders
```

## TYPOGRAPHY QUICK REFERENCE

```
ETextStyles.displaySerif    Playfair Display 900 italic  hero headlines on editorial builds
ETextStyles.displayXL       Space Grotesk 800            hero headlines on bold/corporate builds
ETextStyles.eyebrow         JetBrains Mono w500 3.0ls    ALL section overlines, eyebrow labels
ETextStyles.svcNum          Playfair Display 700 italic  catalogue card numbers (01, 02…)
ETextStyles.svcTag          JetBrains Mono w400 1.5ls    catalogue tags, right-aligned mono labels
ETextStyles.h1 – h3         Space Grotesk                section headings
ETextStyles.bodyLg / body   Playfair Display             editorial body copy
ETextStyles.label / caption Space Grotesk                UI chrome, nav, buttons
```

---

## Design Token System Setup

### lib/core/theme/e_colors.dart
```dart
import 'package:flutter/material.dart';

abstract class EColors {
  // Brand primaries
  static const primary     = Color(0xFF58E3EF); // P-Cyan
  static const accent      = Color(0xFFD34CF1); // A-Magenta
  static const gold        = Color(0xFFFFD700);

  // Backgrounds
  static const background  = Color(0xFF0A0E1A); // Midnight-Base
  static const surface     = Color(0xFF111827); // Circuit-Slate
  static const surfaceAlt  = Color(0xFF1A2332);

  // Text
  static const textPrimary    = Color(0xFFF0F8FF); // cyanTintedWhite
  static const textSecondary  = Color(0xFF8BA3BF);
  static const textMuted      = Color(0xFF4A6080);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error   = Color(0xFFEF4444);

  // Neon glows (use sparingly — for brand moments)
  static const neonCyan    = Color(0x4058E3EF); // 25% opacity cyan
  static const neonMagenta = Color(0x40D34CF1); // 25% opacity magenta
}
```

### lib/core/theme/e_spacing.dart
```dart
abstract class ESpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}
```

### lib/core/theme/e_text_styles.dart
```dart
import 'package:flutter/material.dart';
import 'e_colors.dart';

abstract class ETextStyles {
  static const _fontPlay    = 'Play';
  static const _fontGrotesk = 'SpaceGrotesk';
  static const _fontInter   = 'Inter';

  static const display = TextStyle(
    fontFamily: _fontPlay,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: EColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const headline = TextStyle(
    fontFamily: _fontPlay,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: EColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: _fontGrotesk,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: EColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: _fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: EColors.textSecondary,
    height: 1.6,
  );

  static const label = TextStyle(
    fontFamily: _fontGrotesk,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: EColors.textMuted,
    letterSpacing: 0.8,
  );

  static const neonCyan = TextStyle(
    fontFamily: _fontPlay,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: EColors.primary,
    shadows: [
      Shadow(color: EColors.primary, blurRadius: 8),
      Shadow(color: EColors.primary, blurRadius: 16),
    ],
  );
}
```

## Animation Patterns

### Entrance Animation (every new screen)
```dart
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _FadeSlideIn({required this.child, this.delayMs = 0});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
```

### Neon Pulse (brand accent elements)
```dart
class NeonPulse extends StatefulWidget {
  final Widget child;
  const NeonPulse({super.key, required this.child});

  @override
  State<NeonPulse> createState() => _NeonPulseState();
}

class _NeonPulseState extends State<NeonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.7, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
```

### Press Scale (interactive elements)
```dart
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const PressScale({super.key, required this.child, required this.onTap});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
```

## NeonButton Component
```dart
class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = EColors.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.xl,
          vertical: ESpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 0),
          ],
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: color, strokeWidth: 2),
              )
            : Text(label, style: ETextStyles.title.copyWith(color: color)),
      ),
    );
  }
}
```

## Responsive Layout Pattern
```dart
// lib/core/utils/responsive/responsive_layout.dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext ctx) => MediaQuery.sizeOf(ctx).width < 600;
  static bool isTablet(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    return w >= 600 && w < 1200;
  }
  static bool isDesktop(BuildContext ctx) => MediaQuery.sizeOf(ctx).width >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth >= 1200) return desktop ?? tablet ?? mobile;
        if (constraints.maxWidth >= 600) return tablet ?? mobile;
        return mobile;
      },
    );
  }
}
```

---

## ShimmerPlaceholder — image slot standard

Use this instead of grey boxes, `Placeholder()`, or static assets during scaffolding.
Every instance gets a `// TODO(image-gen):` comment so `/image-gen` can find and replace it.

```dart
// pubspec.yaml: shimmer: ^3.0.0
class ShimmerPlaceholder extends StatelessWidget {
  final double aspectRatio;
  final double borderRadius;
  final String slot;

  const ShimmerPlaceholder({
    super.key,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 8,
    this.slot = 'image',
  });

  @override
  Widget build(BuildContext context) {
    // TODO(image-gen): fill slot — slot
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Shimmer.fromColors(
        baseColor: EColors.surface,
        highlightColor: EColors.surfaceAlt,
        child: Container(
          decoration: BoxDecoration(
            color: EColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
```

**Preset ratios:**
```dart
ShimmerPlaceholder(aspectRatio: 16 / 9, slot: 'hero-background')       // hero
ShimmerPlaceholder(aspectRatio: 4 / 3,  slot: 'service-card-NAME')     // product/service card
ShimmerPlaceholder(aspectRatio: 3 / 4,  slot: 'team-portrait-NAME')    // portrait
ShimmerPlaceholder(aspectRatio: 1 / 1,  slot: 'thumbnail-NAME')        // square thumb
```

---

## Awwwards Motion Widgets

### ParallaxLayer — scroll-driven depth
```dart
// depth: 0.0 = locked to scroll, 1.0 = full speed, 0.3 = slow background
class ParallaxLayer extends StatelessWidget {
  final double depth;
  final Widget child;
  final ScrollController scrollController;

  const ParallaxLayer({
    super.key,
    required this.depth,
    required this.child,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (_, __) {
        final offset = scrollController.hasClients
            ? scrollController.offset * (1.0 - depth)
            : 0.0;
        return Transform.translate(
          offset: Offset(0, -offset),
          child: child,
        );
      },
    );
  }
}
```

### MagneticWidget — cursor attraction
```dart
// CTAs and nav icons: trigger at 80px, max 12px displacement
class MagneticWidget extends StatefulWidget {
  final Widget child;
  final double radius;
  final double strength;

  const MagneticWidget({
    super.key,
    required this.child,
    this.radius = 80,
    this.strength = 12,
  });

  @override
  State<MagneticWidget> createState() => _MagneticWidgetState();
}

class _MagneticWidgetState extends State<MagneticWidget> {
  Offset _displacement = Offset.zero;
  final _key = GlobalKey();

  void _onHover(PointerEvent event) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final delta = event.position - center;
    final dist = delta.distance;
    if (dist < widget.radius) {
      final pull = (1 - dist / widget.radius) * widget.strength;
      setState(() => _displacement = delta / dist * pull);
    } else {
      setState(() => _displacement = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: (_) => setState(() => _displacement = Offset.zero),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _displacement),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (_, offset, child) =>
            Transform.translate(offset: offset, child: child),
        child: SizedBox(key: _key, child: widget.child),
      ),
    );
  }
}
```

### TextReveal — word/character stagger entrance
```dart
enum TextRevealMode { word, character }

class TextReveal extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextRevealMode mode;
  final Duration staggerInterval;
  final int initialDelayMs;

  const TextReveal({
    super.key,
    required this.text,
    this.style,
    this.mode = TextRevealMode.word,
    this.staggerInterval = const Duration(milliseconds: 60),
    this.initialDelayMs = 0,
  });

  @override
  State<TextReveal> createState() => _TextRevealState();
}

class _TextRevealState extends State<TextReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<String> _units;

  @override
  void initState() {
    super.initState();
    _units = widget.mode == TextRevealMode.word
        ? widget.text.split(' ')
        : widget.text.split('');
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.staggerInterval * _units.length,
    );
    Future.delayed(
      Duration(milliseconds: widget.initialDelayMs),
      _ctrl.forward,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: List.generate(_units.length, (i) {
        final start = i / _units.length;
        final end = (i + 1) / _units.length;
        final anim = CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        final separator = widget.mode == TextRevealMode.word ? ' ' : '';
        return ClipRect(
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(anim),
            child: FadeTransition(
              opacity: anim,
              child: Text('${_units[i]}$separator', style: widget.style),
            ),
          ),
        );
      }),
    );
  }
}
```

### TiltCard — 3D perspective hover
```dart
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxAngleDeg;
  final bool enableSpecular;

  const TiltCard({
    super.key,
    required this.child,
    this.maxAngleDeg = 8.0,
    this.enableSpecular = true,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  Offset _cursor = Offset.zero;
  bool _hovering = false;
  final _key = GlobalKey();

  void _onHover(PointerEvent event) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(event.position);
    setState(() {
      _hovering = true;
      _cursor = Offset(
        (local.dx / box.size.width - 0.5) * 2,   // -1..1
        (local.dy / box.size.height - 0.5) * 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final angle = widget.maxAngleDeg * (3.14159 / 180);
    final rx = _hovering ? -_cursor.dy * angle : 0.0;
    final ry = _hovering ? _cursor.dx * angle : 0.0;

    return MouseRegion(
      key: _key,
      onHover: _onHover,
      onExit: (_) => setState(() => _hovering = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) {
          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rx * t)
            ..rotateY(ry * t);
          return Transform(
            transform: matrix,
            alignment: Alignment.center,
            child: Stack(
              children: [
                widget.child,
                if (widget.enableSpecular && _hovering)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(_cursor.dx * 0.5, _cursor.dy * 0.5),
                            radius: 0.8,
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### InertiaCarousel — drag with spring decay
```dart
class InertiaCarousel extends StatefulWidget {
  final List<Widget> children;
  final double itemWidth;
  final double itemSpacing;

  const InertiaCarousel({
    super.key,
    required this.children,
    required this.itemWidth,
    this.itemSpacing = 16,
  });

  @override
  State<InertiaCarousel> createState() => _InertiaCarouselState();
}

class _InertiaCarouselState extends State<InertiaCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _offset = 0;
  double _dragStart = 0;
  double _dragStartOffset = 0;

  double get _stride => widget.itemWidth + widget.itemSpacing;
  double get _maxOffset => -(widget.children.length - 1) * _stride;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this);
    _ctrl.addListener(() => setState(() => _offset = _ctrl.value));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails d) {
    _ctrl.stop();
    _dragStart = d.globalPosition.dx;
    _dragStartOffset = _offset;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.globalPosition.dx - _dragStart;
    setState(() => _offset = (_dragStartOffset + delta).clamp(_maxOffset, 0));
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    final nearest = (_offset / _stride).round() * _stride;
    _ctrl.animateTo(
      nearest.clamp(_maxOffset, 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    // Velocity boost: overshoot toward velocity direction then snap
    if (velocity.abs() > 300) {
      final target = velocity > 0
          ? ((_offset / _stride).floor() * _stride).clamp(_maxOffset, 0)
          : ((_offset / _stride).ceil() * _stride).clamp(_maxOffset, 0);
      _ctrl.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(_offset, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: widget.children
                .map((c) => Padding(
                      padding: EdgeInsets.only(right: widget.itemSpacing),
                      child: SizedBox(width: widget.itemWidth, child: c),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
```

### CursorOverlay — branded cursor (web/desktop)

**IMPORTANT**: Never use `setState` in the cursor overlay — it rebuilds the entire widget tree 60×/second and causes visible mouse lag. The correct pattern uses `ValueNotifier` + `CustomPainter(repaint: Listenable.merge([...]))` so only the canvas layer repaints. This is already built at `core/widgets/cursor_overlay.dart` — import it, don't recreate it.

```dart
// ✅ Correct pattern (already in codebase — import don't rebuild)
// Uses ValueNotifier<Offset> for cursor + ring positions.
// CustomPainter with super(repaint: Listenable.merge([cursorPos, ringPos]))
// Ticker lerps ring at 0.15/frame with NO setState.
// RepaintBoundary isolates canvas from app widget tree.
// kIsWeb guard — returns bare child on native.

import 'core/widgets/cursor_overlay.dart';

// In main.dart builder:
builder: (context, child) => CursorOverlay(child: child ?? const SizedBox());
```

```dart
// ❌ Wrong — causes mouse lag (rebuilds full tree on every hover event + every tick)
class _Bad extends State<CursorOverlay> {
  Offset _dot = Offset.zero;
  late final Ticker _ticker;
  void initState() {
    _ticker = createTicker((_) => setState(() { ... })); // ← full rebuild 60fps
  }
  // onHover: (e) => setState(() => _dot = e.position); // ← full rebuild on move
}
```
