import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../core/theme/personality_theme.dart';
import '../../controllers/home_controller.dart';

// ─── Full-bleed hero ──────────────────────────────────────────────────────────
class HeroFullbleed extends StatelessWidget {
  const HeroFullbleed({super.key});

  @override
  Widget build(BuildContext context) {
    final pt     = PersonalityTheme.fromEnv();
    final height = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height,
      child: Obx(() {
        final ctrl     = Get.find<HomeController>();
        final imageUrl = ctrl.heroImageUrl.isEmpty ? null : ctrl.heroImageUrl;
        final overline = ctrl.heroOverline;
        final tagline  = ctrl.heroTagline;

        return Stack(
          fit: StackFit.expand,
          children: [
            imageUrl != null
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Container(color: EColors.secondary),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: pt.heroContentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ESpacing.pagePaddingH),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: pt.heroTextAlign == TextAlign.left
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      if (overline.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: ESpacing.md),
                          child: Text(
                            overline.toUpperCase(),
                            style: ETextStyles.overline
                                .copyWith(color: EColors.accent),
                            textAlign: pt.heroTextAlign,
                          ),
                        ),
                      Text(
                        AppEnv.clientName,
                        style: ETextStyles.displayXL
                            .copyWith(color: Colors.white),
                        textAlign: pt.heroTextAlign,
                      ),
                      if (tagline.isNotEmpty) ...[
                        const SizedBox(height: ESpacing.lg),
                        Text(
                          tagline,
                          style: ETextStyles.bodyLg
                              .copyWith(color: Colors.white70),
                          textAlign: pt.heroTextAlign,
                        ),
                      ],
                      const SizedBox(height: ESpacing.xxl),
                      _HeroCta(pt: pt),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: ESpacing.xl,
              left: 0, right: 0,
              child: Icon(Icons.keyboard_arrow_down,
                  color: Colors.white54, size: 32),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Split hero ───────────────────────────────────────────────────────────────
class HeroSplit extends StatelessWidget {
  const HeroSplit({super.key});

  @override
  Widget build(BuildContext context) {
    final pt    = PersonalityTheme.fromEnv();
    final width = MediaQuery.of(context).size.width;

    return Obx(() {
      final ctrl     = Get.find<HomeController>();
      final imageUrl = ctrl.heroImageUrl.isEmpty ? null : ctrl.heroImageUrl;
      final overline = ctrl.heroOverline;
      final tagline  = ctrl.heroTagline;

      return Container(
        height: 680,
        color: EColors.surface,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width > ESpacing.desktopBreak
                      ? ESpacing.pagePaddingHDesktop
                      : ESpacing.pagePaddingH,
                  vertical: ESpacing.xxxl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overline.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: ESpacing.md),
                        child: Text(overline.toUpperCase(),
                            style: ETextStyles.overline),
                      ),
                    Text(AppEnv.clientName, style: ETextStyles.displayLg),
                    if (tagline.isNotEmpty) ...[
                      const SizedBox(height: ESpacing.lg),
                      Text(
                        tagline,
                        style: ETextStyles.bodyLg
                            .copyWith(color: EColors.onSurfaceMuted),
                      ),
                    ],
                    const SizedBox(height: ESpacing.xxl),
                    _HeroCta(pt: pt),
                  ],
                ),
              ),
            ),
            Expanded(
              child: imageUrl != null
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover, height: double.infinity)
                  : Container(color: EColors.primaryLight),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Centered hero ────────────────────────────────────────────────────────────
class HeroCentered extends StatelessWidget {
  const HeroCentered({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = PersonalityTheme.fromEnv();

    return Obx(() {
      final ctrl    = Get.find<HomeController>();
      final tagline = ctrl.heroTagline;

      return Container(
        height: 600,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [EColors.primaryLight, EColors.surface],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: pt.heroContentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(ESpacing.pagePaddingH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppEnv.clientName,
                      style: ETextStyles.displayLg,
                      textAlign: TextAlign.center),
                  if (tagline.isNotEmpty) ...[
                    const SizedBox(height: ESpacing.lg),
                    Text(
                      tagline,
                      style: ETextStyles.bodyLg
                          .copyWith(color: EColors.onSurfaceMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: ESpacing.xxl),
                  _HeroCta(pt: pt),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Shared CTA ───────────────────────────────────────────────────────────────
class _HeroCta extends StatelessWidget {
  const _HeroCta({required this.pt});
  final PersonalityTheme pt;

  @override
  Widget build(BuildContext context) {
    final showBooking = AppEnv.moduleEnabled('booking');
    return Wrap(
      spacing: ESpacing.md,
      runSpacing: ESpacing.md,
      children: [
        if (showBooking)
          ElevatedButton(
            onPressed: () => Get.toNamed(ERoutes.booking),
            child: const Text('Book Now'),
          ),
        OutlinedButton(
          onPressed: () => Get.toNamed(ERoutes.contact),
          child: const Text('Get in Touch'),
        ),
      ],
    );
  }
}
