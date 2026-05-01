import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/booking_addons_controller.dart';
import '../controllers/booking_controller.dart';

class BookingSummaryCard extends GetView<BookingController> {
  const BookingSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final artist = controller.selectedArtist.value;
      final slot   = controller.selectedSlot.value;
      if (artist == null || slot == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(ESpacing.lg),
        decoration: BoxDecoration(
          color: EColors.surfaceVariant,
          border: Border.all(color: EColors.primary, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(artist.name,
                      style: ETextStyles.h3,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: ESpacing.sm),
                Text(slot.formattedDate,
                    style: ETextStyles.label.copyWith(
                        color: EColors.onSurfaceMuted)),
              ],
            ),
            if (artist.specialty.isNotEmpty) ...[
              const SizedBox(height: ESpacing.xs),
              Text(artist.specialty.toUpperCase(),
                  style: ETextStyles.overline),
            ],
            const SizedBox(height: ESpacing.xs),
            Text(slot.formattedTime,
                style: ETextStyles.body.copyWith(color: EColors.primary)),
            const SizedBox(height: ESpacing.lg),
            Divider(color: EColors.divider, thickness: 0.5, height: 1),
            const SizedBox(height: ESpacing.md),
            Obx(() {
              final pkgId = controller.selectedPackageId.value;
              if (pkgId == null) return const SizedBox.shrink();
              final pkg = controller.packages
                  .firstWhereOrNull((p) => p.id == pkgId);
              if (pkg == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: ESpacing.xs),
                child: Row(children: [
                  Icon(Icons.local_offer_outlined,
                      size: 14, color: EColors.primary),
                  const SizedBox(width: ESpacing.xs),
                  Text(pkg.name,
                      style: ETextStyles.labelSm
                          .copyWith(color: EColors.primary)),
                  if (pkg.discountPct > 0) ...[
                    const SizedBox(width: ESpacing.xs),
                    Text('(${pkg.discountPct}% off)',
                        style: ETextStyles.labelSm
                            .copyWith(color: EColors.primary)),
                  ],
                ]),
              );
            }),
            ...controller.selectedServices.map((svc) => Padding(
                  padding: const EdgeInsets.only(bottom: ESpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(svc.name, style: ETextStyles.body),
                      Text(svc.formattedDuration,
                          style: ETextStyles.duration),
                    ],
                  ),
                )),
            const SizedBox(height: ESpacing.sm),
            Divider(color: EColors.divider, thickness: 0.5, height: 1),
            const SizedBox(height: ESpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL DURATION',
                    style:
                        ETextStyles.label.copyWith(color: EColors.onSurfaceMuted)),
                Text(controller.formattedTotalDuration,
                    style: ETextStyles.body),
              ],
            ),
            const SizedBox(height: ESpacing.xs),
            Obx(() {
              final addons = Get.find<BookingAddonsController>();
              final total  = controller.totalPrice;
              final deposit = addons.depositDue(total);
              final hasDiscount = addons.hasDiscount;
              final depositPct  = addons.depositPct.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL',
                          style: ETextStyles.label.copyWith(
                              color: EColors.onSurfaceMuted)),
                      Text('\$${total.toStringAsFixed(2)}',
                          style: hasDiscount
                              ? ETextStyles.price.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: EColors.onSurfaceMuted)
                              : ETextStyles.price),
                    ],
                  ),
                  if (addons.hasVoucher) ...[
                    const SizedBox(height: ESpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GIFT VOUCHER',
                            style: ETextStyles.label.copyWith(
                                color: EColors.primary)),
                        Text('- \$${addons.giftDiscountDollars.toStringAsFixed(2)}',
                            style: ETextStyles.body.copyWith(
                                color: EColors.primary)),
                      ],
                    ),
                  ],
                  if (addons.hasLoyaltyRedeem) ...[
                    const SizedBox(height: ESpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('LOYALTY POINTS',
                            style: ETextStyles.label.copyWith(
                                color: EColors.primary)),
                        Text('- \$${addons.loyaltyDiscountDollars.toStringAsFixed(2)}',
                            style: ETextStyles.body.copyWith(
                                color: EColors.primary)),
                      ],
                    ),
                  ],
                  if (addons.hasTip) ...[
                    const SizedBox(height: ESpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GRATUITY',
                            style: ETextStyles.label.copyWith(color: EColors.onSurfaceMuted)),
                        Text('+ \$${addons.tipDollars.toStringAsFixed(2)}',
                            style: ETextStyles.body),
                      ],
                    ),
                  ],
                  if (!addons.isPaymentRequired) ...[
                    const SizedBox(height: ESpacing.xs),
                    Divider(color: EColors.divider, thickness: 0.5, height: 1),
                    const SizedBox(height: ESpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DUE NOW',
                            style: ETextStyles.label.copyWith(
                                color: EColors.onSurface)),
                        Text('Pay at appointment',
                            style: ETextStyles.bodyMd.copyWith(
                                color: EColors.onSurfaceMuted)),
                      ],
                    ),
                  ] else if (hasDiscount) ...[
                    const SizedBox(height: ESpacing.xs),
                    Divider(color: EColors.divider, thickness: 0.5, height: 1),
                    const SizedBox(height: ESpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(addons.isDepositEnabled
                            ? 'DUE NOW ($depositPct%)'
                            : 'DUE NOW',
                            style: ETextStyles.label.copyWith(
                                color: EColors.onSurface)),
                        Text('\$${deposit.toStringAsFixed(2)}',
                            style: ETextStyles.price),
                      ],
                    ),
                  ] else if (addons.isDepositEnabled) ...[
                    const SizedBox(height: ESpacing.xs),
                    Divider(color: EColors.divider, thickness: 0.5, height: 1),
                    const SizedBox(height: ESpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DUE NOW ($depositPct%)',
                            style: ETextStyles.label.copyWith(
                                color: EColors.onSurface)),
                        Text('\$${deposit.toStringAsFixed(2)}',
                            style: ETextStyles.price),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BALANCE AT APPOINTMENT',
                            style: ETextStyles.label.copyWith(
                                color: EColors.onSurfaceMuted)),
                        Text('\$${(total - deposit).toStringAsFixed(2)}',
                            style: ETextStyles.body),
                      ],
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      );
    });
  }
}
