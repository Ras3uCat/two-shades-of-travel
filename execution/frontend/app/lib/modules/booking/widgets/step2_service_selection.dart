import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/booking_controller.dart';
import '../models/package_model.dart';
import '../models/service_model.dart';
import 'artist_card.dart';
import 'duration_total_bar.dart';
import 'service_card.dart';

class Step2ServiceSelection extends GetView<BookingController> {
  const Step2ServiceSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < ESpacing.mobileBreak;
    final hPad = isMobile ? ESpacing.md : ESpacing.xxl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: ESpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STEP 02', style: ETextStyles.overline),
              const SizedBox(height: ESpacing.sm),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: ESpacing.md),
              Text('SELECT SERVICES', style: ETextStyles.h2),
              const SizedBox(height: ESpacing.sm),
              Text(
                "Pick one or more. We'll calculate your session length.",
                style: ETextStyles.bodyMuted,
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() => SingleChildScrollView(
                padding: EdgeInsets.only(
                    left: hPad, right: hPad, bottom: ESpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.packages.isNotEmpty)
                      _PackageRow(hPad: hPad),
                    ..._buildServiceGroups(controller, isMobile),
                    if (controller.isAnyArtist.value)
                      _InlineArtistPicker(isMobile: isMobile),
                  ],
                ),
              )),
        ),
        Obx(() => DurationTotalBar(
              canContinue: controller.canProceedStep2,
              onContinue: () => controller.proceedFromStep2(),
            )),
      ],
    );
  }

  List<Widget> _buildServiceGroups(
      BookingController ctrl, bool isMobile) {
    final groups = <String, List<ServiceModel>>{};
    for (final svc in ctrl.availableServices) {
      groups.putIfAbsent(svc.category, () => []).add(svc);
    }

    return groups.entries.expand((entry) {
      final crossCount = isMobile ? 1 : 3;
      return <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: ESpacing.sm, top: ESpacing.lg),
          child: Row(children: [
            Text(entry.key.toUpperCase(), style: ETextStyles.label),
            const SizedBox(width: ESpacing.md),
            Expanded(
                child: Divider(
                    color: EColors.divider, thickness: 0.5, height: 1)),
          ]),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: ESpacing.md,
            mainAxisSpacing: ESpacing.md,
            childAspectRatio: isMobile ? 3.0 : 2.2,
          ),
          itemCount: entry.value.length,
          itemBuilder: (_, i) {
            final svc = entry.value[i];
            return Obx(() => ServiceCard(
                  service: svc,
                  isSelected: ctrl.selectedServiceIds.contains(svc.id),
                  onTap: () => ctrl.toggleService(svc.id),
                ));
          },
        ),
      ];
    }).toList();
  }
}

// ── Package row ───────────────────────────────────────────────────────────────
class _PackageRow extends GetView<BookingController> {
  const _PackageRow({required this.hPad});
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pkgs = controller.packages;
      if (pkgs.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ESpacing.lg),
          Row(children: [
            Text('BUNDLE DEALS', style: ETextStyles.label),
            const SizedBox(width: ESpacing.md),
            Expanded(
                child: Divider(
                    color: EColors.primary, thickness: 0.5, height: 1)),
          ]),
          const SizedBox(height: ESpacing.md),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pkgs.length,
              separatorBuilder: (_, _) => const SizedBox(width: ESpacing.md),
              itemBuilder: (_, i) =>
                  Obx(() => _PackageCard(pkg: pkgs[i])),
            ),
          ),
          const SizedBox(height: ESpacing.sm),
        ],
      );
    });
  }
}

class _PackageCard extends GetView<BookingController> {
  const _PackageCard({required this.pkg});
  final PackageModel pkg;

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.selectedPackageId.value == pkg.id;
    final price      = pkg.formattedPrice(controller.services);

    return GestureDetector(
      onTap: () => controller.selectPackage(pkg),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(ESpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? EColors.primary.withValues(alpha: 0.08)
              : EColors.surfaceVariant,
          border: Border.all(
            color: isSelected ? EColors.primary : EColors.divider,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(pkg.name,
                    style: ETextStyles.label.copyWith(
                        color: isSelected
                            ? EColors.primary
                            : EColors.onSurface),
                    overflow: TextOverflow.ellipsis),
              ),
              if (pkg.discountPct > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ESpacing.xs, vertical: 2),
                  color: EColors.primary,
                  child: Text('${pkg.discountPct}% OFF',
                      style: ETextStyles.labelSm.copyWith(
                          color: EColors.secondary,
                          fontSize: 9)),
                ),
            ]),
            const SizedBox(height: ESpacing.xs),
            Text(
              '${pkg.serviceIds.length} service${pkg.serviceIds.length == 1 ? '' : 's'}',
              style: ETextStyles.bodySmMuted,
            ),
            const Spacer(),
            Text(price,
                style: ETextStyles.price.copyWith(
                    fontSize: 14,
                    color: isSelected
                        ? EColors.primary
                        : EColors.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _InlineArtistPicker extends GetView<BookingController> {
  const _InlineArtistPicker({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final artists = controller.filteredArtists;
      if (controller.selectedServiceIds.isEmpty) return const SizedBox.shrink();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        constraints: BoxConstraints(maxHeight: artists.isEmpty ? 80 : 250),
        margin: const EdgeInsets.only(top: ESpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('AVAILABLE ARTISTS', style: ETextStyles.label),
              const SizedBox(width: ESpacing.md),
              Expanded(
                  child: Divider(
                      color: EColors.primary, thickness: 0.5, height: 1)),
            ]),
            const SizedBox(height: ESpacing.md),
            if (artists.isEmpty)
              Text('No artists offer all selected services.',
                  style: ETextStyles.bodySmMuted)
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: artists.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: ESpacing.md),
                  itemBuilder: (_, i) => Obx(() => ArtistCard(
                        artist: artists[i],
                        isSelected:
                            controller.selectedArtist.value?.id == artists[i].id,
                        onTap: () =>
                            controller.selectFilteredArtist(artists[i]),
                        compact: true,
                      )),
                ),
              ),
          ],
        ),
      );
    });
  }
}
