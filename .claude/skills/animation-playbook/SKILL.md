---
name: animation-playbook
description: >
  Advanced motion and interaction playbook for Awwwards/Dribbble-tier Flutter builds.
  Covers Rive, Lottie, shader/canvas painting, scroll-progress reveals, stagger
  orchestration, and motion budget rules. Load alongside frontend-design for any
  section with high-impact animation requirements.
---

# Animation Playbook

This skill handles the "build the wow" layer — everything beyond entrance animations and hover states. Load this when a task involves Rive, Lottie, canvas effects, scroll-triggered reveals, or orchestrating complex stagger sequences.

---

## Decision Tree: Which tool for which job?

| Need | Tool |
|------|------|
| Complex state machine (character, logo, UI states) | **Rive** |
| One-shot or looping illustrative animation | **Lottie** |
| Noise / aurora / particle / generative background | **CustomPainter** (Canvas) |
| Scroll-triggered section reveal | **VisibilityDetector** |
| Video that animates on scroll (Apple-style) | **scroll-stop-builder** skill |
| Layout-bound transitions (size, color, position) | **Flutter native** (AnimatedContainer, TweenAnimationBuilder) |
| Multiple coordinated entrances | **StaggerGroup** pattern |

---

## Rive Integration

### When to use
- Logo animations with interactive states (idle → hover → active)
- Onboarding illustrations with branching states
- Game-like UI elements (progress bars, achievements, mascots)

### Setup
```yaml
# pubspec.yaml
dependencies:
  rive: ^0.13.0
```

### Pattern — State Machine
```dart
class RiveStateWidget extends StatefulWidget {
  final String assetPath;   // e.g. 'assets/animations/logo.riv'
  final String stateMachine;
  final String inputName;

  const RiveStateWidget({
    super.key,
    required this.assetPath,
    required this.stateMachine,
    required this.inputName,
  });

  @override
  State<RiveStateWidget> createState() => _RiveStateWidgetState();
}

class _RiveStateWidgetState extends State<RiveStateWidget> {
  SMIBool? _input;

  void _onRiveInit(Artboard artboard) {
    final ctrl = StateMachineController.fromArtboard(
      artboard,
      widget.stateMachine,
    );
    if (ctrl == null) return;
    artboard.addController(ctrl);
    _input = ctrl.findInput<bool>(widget.inputName) as SMIBool?;
  }

  void trigger(bool value) => _input?.change(value);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => trigger(true),
      onExit: (_) => trigger(false),
      child: RiveAnimation.asset(
        widget.assetPath,
        onInit: _onRiveInit,
        fit: BoxFit.contain,
      ),
    );
  }
}
```

### Rules
- Export `.riv` files at 2x for retina clarity.
- Keep state machines to ≤5 states per artboard — complex branching → split artboards.
- Use `fit: BoxFit.contain` to avoid stretching on resize.
- Rive runs on its own thread — no `AnimationController` needed.

---

## Lottie Integration

### When to use
- Hero loading / skeleton transition sequences
- Success / error microinteractions (checkmark, X, confetti)
- Illustrative one-shot or looping background elements

### Setup
```yaml
# pubspec.yaml
dependencies:
  lottie: ^3.1.0
```

### Pattern — Controlled playback
```dart
class LottieMicro extends StatefulWidget {
  final String assetPath;
  final bool loop;
  final double size;

  const LottieMicro({
    super.key,
    required this.assetPath,
    this.loop = false,
    this.size = 80,
  });

  @override
  State<LottieMicro> createState() => _LottieMicroState();
}

class _LottieMicroState extends State<LottieMicro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    if (!widget.loop) {
      // Play once then hold on last frame
      _ctrl.addStatusListener((s) {
        if (s == AnimationStatus.completed) _ctrl.stop();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void play() => widget.loop ? _ctrl.repeat() : _ctrl.forward(from: 0);
  void reset() => _ctrl.reset();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Lottie.asset(
        widget.assetPath,
        controller: _ctrl,
        onLoaded: (comp) {
          _ctrl.duration = comp.duration;
          play();
        },
        repeat: widget.loop,
      ),
    );
  }
}
```

### Rules
- Export from After Effects at 1x — Lottie scales cleanly.
- Prefer `.json` over `.lottie` binary unless file size is critical (>200KB).
- Never run Lottie on initial page load if it's decorative — lazy trigger via `VisibilityDetector`.
- Max 2 simultaneous Lottie instances — they are CPU-bound.

---

## CustomPainter — Ambient Backgrounds

### Noise / Grain texture
```dart
class NoisePainter extends CustomPainter {
  final double opacity;
  NoisePainter({this.opacity = 0.04});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42); // fixed seed = consistent noise
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < (size.width * size.height * 0.15).toInt(); i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      paint.color = Colors.white.withValues(alpha: rng.nextDouble() * opacity);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(NoisePainter old) => false; // static, no repaint needed
}
```

### Floating particles (ambient hero background)
```dart
// Use a Ticker-driven CustomPainter.
// Each particle: position, velocity, radius, opacity.
// Update position each tick. Wrap at edges.
// Keep to ≤60 particles for 60fps budget.
class ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        Paint()
          ..color = EColors.primary.withValues(alpha: p.opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) => true;
}
```

### Rules
- Always `shouldRepaint → false` for static painters (noise, grain).
- Static painters: call once in `initState`, re-use the same `CustomPaint` widget.
- Animated painters: drive via `Ticker`, NOT `AnimationController.repeat()` (avoid unnecessary rebuilds).
- Keep particle count ≤60 and radius ≤2px for GPU raster budget.

---

## Scroll-Progress Reveals

### Setup
```yaml
dependencies:
  visibility_detector: ^0.4.0
```

### Pattern — trigger-once entrance
```dart
class RevealOnScroll extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const RevealOnScroll({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_triggered && info.visibleFraction > 0.2) {
      _triggered = true;
      Future.delayed(widget.delay, _ctrl.forward);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: key ?? ValueKey(widget.child.hashCode),
      onVisibilityChanged: _onVisibilityChanged,
      child: FadeTransition(
        opacity: _ctrl,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
          child: widget.child,
        ),
      ),
    );
  }
}
```

### Rules
- `visibleFraction > 0.2` threshold — triggers when 20% of the element is in view.
- `_triggered` guard — fires once only (not on every re-scroll).
- For repeating reveals (e.g. counters), remove the guard.

---

## StaggerGroup — Automatic delay orchestration

Wraps N children and assigns staggered entrance delays automatically.

```dart
class StaggerGroup extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerInterval;
  final int initialDelayMs;

  const StaggerGroup({
    super.key,
    required this.children,
    this.staggerInterval = const Duration(milliseconds: 80),
    this.initialDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (i) {
        return RevealOnScroll(
          delay: Duration(
            milliseconds: initialDelayMs + staggerInterval.inMilliseconds * i,
          ),
          child: children[i],
        );
      }),
    );
  }
}
```

---

## Motion Budget

**Hard limit: max 3 simultaneous animations per screen.**

| Tier | Budget | What counts |
|------|--------|-------------|
| Background | 1 slot | Ambient noise painter OR particle system OR gradient drift — pick one |
| Content | 1 slot | Stagger reveal group OR scroll-driven transform |
| Interaction | 1 slot | Hover tilt / magnetic / cursor overlay |

If a design calls for more: consolidate (merge ambient into one `CustomPainter`) or gate behind user interaction (don't autoplay secondary effects until primary is complete).

**Thread rule**: Any animation touching >100 elements → move to a background isolate or use `compute()`. Painters with `shouldRepaint → true` are GPU-bound — keep raster work cheap (circles, not paths).

---

## Page Transitions

### Clip-path wipe (default)
```dart
PageRouteBuilder(
  pageBuilder: (_, __, ___) => const NextView(),
  transitionDuration: const Duration(milliseconds: 350),
  transitionsBuilder: (_, anim, __, child) {
    return ClipPath(
      clipper: _DiagonalWipeClipper(anim.value),
      child: child,
    );
  },
);

class _DiagonalWipeClipper extends CustomClipper<Path> {
  final double progress;
  _DiagonalWipeClipper(this.progress);

  @override
  Path getClip(Size size) {
    final p = Path();
    final x = size.width * progress;
    p.moveTo(0, 0);
    p.lineTo(x + size.height * 0.3, 0);
    p.lineTo(x, size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_DiagonalWipeClipper old) => old.progress != progress;
}
```

### Hero shared element
```dart
// Wrap source widget:
Hero(tag: 'product-${item.id}', child: ProductImage(item));

// Wrap destination widget (same tag):
Hero(
  tag: 'product-${item.id}',
  flightShuttleBuilder: (_, anim, __, ___, ____) {
    return ScaleTransition(
      scale: anim.drive(Tween(begin: 0.8, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutCubic))),
      child: ProductImage(item),
    );
  },
  child: ProductImage(item),
);
```
