# Frontend Design System Layer
**Skill Name** frontend-design
**Description** Create distinctive, production-grade frontend interfaces with intentional, high-end design quality.
Used when building UI, screens, components, dashboards, or visual experiences.

**Design Thinking Workflow (MANDATORY BEFORE CODING)**
- **Purpose**
    - What problem does this UI solve?
    - Who is using it?
- **Tone Selection (Pick ONE Bold Direction)**
    - Choose a strong visual identity:
    - Brutalist / Raw
    - Retro-Futuristic
    - Editorial / Magazine
    - Luxury / High-End
    - Soft / Organic
    - Geometric / Art Deco
    - Playful / Toy-like
    - Industrial / Tactical
    - Minimal Zen
    - Maximalist Chaos
    - The design must commit fully to the chosen tone.
- **Differentiation Anchor**
    - Define one unforgettable visual element, such as:
        - signature animation (see `scroll-stop-builder` skill for specialized video-scroll effects)
        - geometric layout system
        - bold type treatment
        - interactive gesture
        - layered glassmorphism
        - asymmetric layout

- **Flutter-Specific Design Translation**
    - Since this is Flutter (not HTML), map aesthetics to:
        - Web Concept	Flutter Equivalent
        - CSS variables	EColors, ThemeData, extensions
        - Grid layouts	GridView, CustomMultiChildLayout
        - Overlapping layouts	Stack + Positioned
        - Animations	AnimatedContainer, TweenAnimationBuilder, AnimationController
        - Scroll effects	CustomScrollView, Slivers
        - Hover effects	MouseRegion (desktop/web)
        - Glass / blur	BackdropFilter
        - Gradients	LinearGradient, ShaderMask
        - Parallax	ScrollController + AnimatedBuilder + Transform.translate
        - Magnetic hover	MouseRegion + Offset math + TweenAnimationBuilder
        - 3D card tilt	Matrix4.identity()..setEntry(3,2,0.001) + Transform
        - Custom cursor	Listener (PointerMoveEvent) + Stack overlay + Ticker
        - Drag inertia	GestureDetector velocity + SpringSimulation / FrictionSimulation
        - Text reveal	ClipRect + SlideTransition per word/char + stagger delay
        - Ambient background	CustomPainter (noise/particles) or slow AnimatedContainer gradient
        - Page transitions	PageRouteBuilder with ClipPath or Hero widget

- **Identity System Layer (Augmented Template)**
    - This project serves as a template. Balance the `ras3uCat` DNA with the client's vision.
    - **Identity Source**: Always refer to `planning/BRAND_KIT.md` for the current active brand tokens.
    - **Glimpses of Ras3uCat**: Even when rebranding, maintain "tactical glances" (sigils in corners, geometric grids, modular progress bars) to preserve project identity.

- **Style Toggles & Config (ThemeExtensions)**
    - Use `BrandTheme` extension to control visual modes.
    - **Toggleability**:
        - `enableNeon`: Controls if text/borders have glowing neon effects (default true for Ras3uCat, may be false for clients).
        - `enableGlow`: Global toggle for shadow blurs and bloom.
        - `enableGeometricMotifs`: Toggle for triangle/grid background painters.
    - If a client brand is "Minimalist", turn off neon/geometric but keep the layout precision.

- **Modular Branding & Swappable Widgets**
    - Never hardcode brand-specific details. Use abstract interfaces.
    - **Reusability**: Build widgets like `EBrandButton` or `EBrandCard` that adapt based on the active brand configuration.
    - **Swappability**: Ensure the architecture allows replacing a `NeonButton` with a `MinimalGlassButton` by simply swapping the component reference in the design system.

- **Aesthetic Execution Rules**
    - **Typography**
        - Use distinctive font pairings (refer to `BRAND_KIT.md`).
        - Avoid default system fonts. Use size contrast aggressively.
    - **Color System**
        - Define palette in `EColors`.
        - **Rule**: Never use pure white for body text in dark themes; use tinted variants (e.g., `cyanTintedWhite`).
        - Priority: Dominant base + sharp accents. Avoid evenly distributed palettes.
    - **Synergy with Latest Trends**
        - While staying "Tactical", incorporate:
            - Bento-grid layouts for dashboards.
            - Layered glassmorphism with grain textures.
            - Dynamic micro-interactions that feel "mechanical" or "systemic".

- **Motion & Interaction**
    - Prioritize:
        - Page load entrance sequences (staggered).
        - Meaningful micro-interactions (hover = activation).
        - **Avoid**: Random motion or "bouncy" easing. Stick to precise, linear-to-ease motions.

- **Awwwards Motion Doctrine (Mandatory for client-facing work)**
    - **Core Law**: If a user can land on a section and leave without noticing motion, the section failed.
    - **Before building any animation widget**: Check `DETAILED_GUIDE.md` Project Widget Catalog. If the need is already covered by an existing widget, import it — do not rebuild.
    - **Parallax layers**: Every hero must have ≥2 depth layers. Background depth `0.2`, midground `0.5`, foreground `1.0`. Use `AmbientHeroBackground` (first Stack layer) + scroll-driven `Transform.translate`.
    - **Magnetic zones**: All primary CTAs and nav icons must react to cursor proximity. Trigger at 80px radius, max 12px displacement. Use `MagneticWidget` (`core/widgets/magnetic_widget.dart`).
    - **Text reveal policy**: Headlines never *appear* — they *arrive*. Use `TextReveal` (`core/widgets/text_reveal.dart`) with mode `word` (default) or `character` (short punchy copy).
    - **3D card tilt**: Any primary content card (portfolio, product, service) gets perspective tilt on hover. Max ±8deg X/Y. Use `TiltCard` (`core/widgets/tilt_card.dart`).
    - **Drag inertia**: Carousels and horizontal sections use spring-decay physics — never instant snap. Use `InertiaCarousel` (`core/widgets/inertia_carousel.dart`).
    - **Custom cursor (web/desktop)**: Use `CursorOverlay` (`core/widgets/cursor_overlay.dart`) — already wired at app root in `main.dart`. Never rebuild using `setState`; it causes visible mouse lag. The `ValueNotifier` + `CustomPainter(repaint: Listenable.merge([...]))` pattern is the only correct implementation.
    - **Page loader**: Every client site shows `AppLoader` (`core/widgets/app_loader.dart`) on first load — animated ring + curtain reveal. Already wired in `main.dart`. Do not remove.
    - **Marquee strip**: Editorial/artisan/food brands must include `MarqueeSection` (`core/widgets/marquee_section.dart`) between hero and first content section.
    - **Section dividers**: Never use `Divider()` between home sections. Use `SectionDivider` (`core/widgets/section_divider.dart`) — gold hairline + diamond ornament.
    - **Scroll reveals**: Every section below the hero uses `RevealOnScroll` (`core/widgets/reveal_on_scroll.dart`) with staggered `delay:` (50ms increments per section).
    - **Page transitions**: Routes never cut. Default: diagonal clip-path wipe at 350ms `easeInOutCubic`. Shared elements: `Hero` with `flightShuttleBuilder`.
    - **Ambient backgrounds**: Hero sections use `AmbientHeroBackground` (gradient drift + noise layer). Never a frozen static background.
    - **Easing law**: `easeOutCubic` for entrances. `easeInCubic` for exits. `easeInOutCubic` for state changes. Never `Curves.bounceOut` on brand work.
    - **Duration law**: Micro (100–150ms): press, tap feedback. Element (250–400ms): card hover, reveal. Page (350–500ms): route transitions. Never exceed 600ms.
    - **See `animation-playbook` skill for**: Rive/Lottie integration, shader painting, scroll-progress reveals, stagger orchestration.

- **Spatial Composition**
    - Avoid boring center-column layouts. Use:
        - Asymmetry and diagonal flow.
        - Overlapping elements with `Stack`.
        - Negative space for "Luxury" or dense blocks for "Editorial".

- **Output Requirements When This Skill Is Triggered**
    - When generating UI:
        - 1. Check `BRAND_KIT.md` for active tokens.
        - 2. If `planning/client/brand_alignment.md` was generated with ui-ux-pro-max enrichment, Section A colors/fonts are industry-validated — apply them directly without overriding.
        - 3. **Check `DETAILED_GUIDE.md` Project Widget Catalog** — identify which existing widgets apply to this screen before writing any new animation code.
        - 4. Run the **Premium Design Checklist** in `DETAILED_GUIDE.md` before marking any screen complete.
        - 5. Implement swappable widgets using semantic naming.
        - 6. Follow Flutter architecture rules first (300-line limit, no business logic in widgets, EColors/ESpacing/ETextStyles only).
        - 7. Provide: Screen, Modular Widgets, Controller, Constants.
        - 8. Include "Sync complete △ M3OW" (or rebranding equivalent) in footers.

- **Philosophy**
    - Your apps should feel like:
        - A crafted product, not a template.
        - A designed experience, not just a UI.
        - A brand, not just a screen.
        - **Swappable yet soulful.**

- **Final Rule**
    - Engineering quality is required.
    - Design excellence is expected.
    - Both must exist together.