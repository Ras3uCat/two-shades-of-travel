import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../core/theme/personality_theme.dart';
import '../../../../core/config/app_env.dart';
import '../../../booking/models/artist_model.dart';
import '../../controllers/home_controller.dart';
import 'section_shared_widgets.dart';

// ─── Services Section ─────────────────────────────────────────────────────────
class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = PersonalityTheme.fromEnv();
    final isDesktop = MediaQuery.sizeOf(context).width > ESpacing.tabletBreak;

    return Obx(() {
      final ctrl = Get.find<HomeController>();
      if (ctrl.services.isEmpty) return const SizedBox.shrink();

      return SectionWrapper(
        child: Column(
          children: [
            SectionHeader(
              overline: ctrl.servicesOverline,
              title: ctrl.servicesTitle,
              subtitle: ctrl.servicesSubtitle.isEmpty
                  ? null
                  : ctrl.servicesSubtitle,
              textAlign: pt.heroTextAlign,
            ),
            const SizedBox(height: ESpacing.xxl),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 1,
                crossAxisSpacing: ESpacing.lg,
                mainAxisSpacing: ESpacing.lg,
                childAspectRatio: isDesktop ? 1.0 : 3.0,
              ),
              itemCount: ctrl.services.length,
              itemBuilder: (_, i) => ServiceCard(
                service: ctrl.services[i],
                pt: pt,
                onTap: () =>
                    Get.toNamed('${ERoutes.services}/${ctrl.services[i].slug}'),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Team Section ─────────────────────────────────────────────────────────────
class TeamSection extends StatelessWidget {
  const TeamSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = PersonalityTheme.fromEnv();
    final isMobile = MediaQuery.sizeOf(context).width < ESpacing.tabletBreak;

    return Obx(() {
      final ctrl = Get.find<HomeController>();
      if (ctrl.teamMembers.isEmpty) return const SizedBox.shrink();

      return SectionWrapper(
        useAltBackground: true,
        child: Column(
          children: [
            SectionHeader(
              overline: 'The Team',
              title: 'Meet Our Specialists',
              textAlign: pt.heroTextAlign,
            ),
            const SizedBox(height: ESpacing.xxl),
            Wrap(
              spacing: ESpacing.lg,
              runSpacing: ESpacing.lg,
              alignment: WrapAlignment.center,
              children: ctrl.teamMembers
                  .map((m) => _TeamCard(member: m, isMobile: isMobile))
                  .toList(),
            ),
          ],
        ),
      );
    });
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.member, required this.isMobile});
  final ArtistModel member;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isMobile ? double.infinity : 260,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: member.photoUrl != null
                  ? Image.network(member.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: EColors.primaryLight,
                      child: Center(
                        child: Icon(
                          Icons.person_outline,
                          size: 64,
                          color: EColors.primary,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESpacing.lg),
              child: Column(
                children: [
                  Text(member.name, style: ETextStyles.h3),
                  if (member.specialty.isNotEmpty) ...[
                    const SizedBox(height: ESpacing.xs),
                    Text(member.specialty, style: ETextStyles.bodySmMuted),
                  ],
                  if (member.bio.isNotEmpty) ...[
                    const SizedBox(height: ESpacing.sm),
                    Text(
                      member.bio,
                      style: ETextStyles.bodySmMuted,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CTA Section ─────────────────────────────────────────────────────────────
class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = Get.find<HomeController>();
      return Container(
        color: EColors.primary,
        padding: const EdgeInsets.symmetric(
          vertical: ESpacing.xxxl,
          horizontal: ESpacing.pagePaddingH,
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                ctrl.ctaTitle,
                style: ETextStyles.displayMd.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESpacing.lg),
              OutlinedButton(
                onPressed: AppEnv.moduleEnabled('booking')
                    ? () => Get.toNamed(ERoutes.booking)
                    : () => Get.toNamed(ERoutes.contact),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: Text(ctrl.ctaButtonLabel),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// (Removed private _SectionWrapper and _SectionHeader)
