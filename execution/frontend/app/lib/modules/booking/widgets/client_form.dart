import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_env.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../core/theme/e_colors.dart';
import '../controllers/booking_addons_controller.dart';
import '../controllers/booking_controller.dart';
import 'tip_selector.dart';

class ClientForm extends GetView<BookingController> {
  const ClientForm({super.key});

  @override
  Widget build(BuildContext context) {
    final addons = Get.find<BookingAddonsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR DETAILS', style: ETextStyles.label),
        const SizedBox(height: ESpacing.md),
        TextFormField(
          style: ETextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'FULL NAME',
            labelStyle: ETextStyles.inputLabel,
          ),
          onChanged: (v) => controller.clientName.value = v,
        ),
        const SizedBox(height: ESpacing.md),
        TextFormField(
          style: ETextStyles.inputText,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'EMAIL',
            labelStyle: ETextStyles.inputLabel,
          ),
          onChanged: (v) {
            controller.clientEmail.value = v;
            if (AppEnv.loyaltyEnabled) addons.loadLoyaltyBalance(v.trim());
          },
        ),
        if (AppEnv.smsEnabled) ...[
          const SizedBox(height: ESpacing.md),
          TextFormField(
            style: ETextStyles.inputText,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'PHONE (for SMS reminders, optional)',
              labelStyle: ETextStyles.inputLabel,
            ),
            onChanged: (v) => addons.smsPhone.value = v,
          ),
        ],
        const SizedBox(height: ESpacing.md),
        TextFormField(
          style: ETextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'PROMO CODE (optional)',
            labelStyle: ETextStyles.inputLabel,
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) =>
              controller.promoCode.value = v.trim().isEmpty ? null : v.trim(),
        ),
        if (AppEnv.giftEnabled) ...[
          const SizedBox(height: ESpacing.md),
          GiftVoucherField(addons: addons),
        ],
        if (AppEnv.loyaltyEnabled) ...[
          const SizedBox(height: ESpacing.md),
          LoyaltyRow(addons: addons, controller: controller),
        ],
        const SizedBox(height: ESpacing.md),
        TextFormField(
          style: ETextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'Notes for your artist (optional)',
            labelStyle: ETextStyles.inputLabel,
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          onChanged: (v) => controller.clientNotes.value = v,
        ),
        if (AppEnv.tipEnabled && addons.isPaymentRequired) ...[
          const SizedBox(height: ESpacing.md),
          TipSelector(addons: addons, totalPrice: controller.totalPrice),
        ],
      ],
    );
  }
}

class GiftVoucherField extends StatelessWidget {
  const GiftVoucherField({super.key, required this.addons});
  final BookingAddonsController addons;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              style: ETextStyles.inputText,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'GIFT VOUCHER CODE (optional)',
                labelStyle: ETextStyles.inputLabel,
                suffixIcon: addons.isValidatingVoucher.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : addons.hasVoucher
                        ? Icon(Icons.check_circle,
                            color: EColors.primary, size: 20)
                        : null,
              ),
              onChanged: (v) {
                addons.giftVoucherCode.value = v;
                if (v.trim().length >= 6) addons.validateGiftVoucher(v);
                if (v.trim().isEmpty) addons.validateGiftVoucher('');
              },
            ),
            if (addons.voucherError.value != null) ...[
              const SizedBox(height: ESpacing.xs),
              Text(addons.voucherError.value!,
                  style: ETextStyles.bodySm.copyWith(color: EColors.error)),
            ],
            if (addons.hasVoucher) ...[
              const SizedBox(height: ESpacing.xs),
              Text(
                'Voucher applied: \$${addons.giftDiscountDollars.toStringAsFixed(2)} off',
                style: ETextStyles.bodySm.copyWith(color: EColors.primary),
              ),
            ],
          ],
        ));
  }
}

class LoyaltyRow extends StatelessWidget {
  const LoyaltyRow({super.key, required this.addons, required this.controller});
  final BookingAddonsController addons;
  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (addons.isLoadingLoyalty.value) {
        return const SizedBox(height: 24, child: LinearProgressIndicator());
      }
      final balance = addons.loyaltyBalance.value;
      if (balance == 0) return const SizedBox.shrink();
      final canRedeem = addons.canRedeem(controller.totalPrice);
      final isApplied = addons.hasLoyaltyRedeem;
      return Container(
        padding: const EdgeInsets.all(ESpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isApplied ? EColors.primary : EColors.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.stars_outlined,
                color: isApplied ? EColors.primary : EColors.onSurfaceMuted,
                size: 18),
            const SizedBox(width: ESpacing.sm),
            Expanded(
              child: Text(
                isApplied
                    ? 'Loyalty: -\$${addons.loyaltyDiscountDollars.toStringAsFixed(2)} applied'
                    : '$balance pts (worth \$${(balance * addons.loyaltyCentsPerPoint.value / 100).toStringAsFixed(2)})',
                style: ETextStyles.bodySm.copyWith(
                    color: isApplied ? EColors.primary : EColors.onSurface),
              ),
            ),
            if (canRedeem)
              TextButton(
                onPressed: isApplied
                    ? addons.clearLoyaltyRedeem
                    : () => addons.applyLoyaltyPoints(controller.totalPrice),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text(isApplied ? 'REMOVE' : 'APPLY',
                    style: ETextStyles.labelSm
                        .copyWith(color: EColors.primary)),
              ),
          ],
        ),
      );
    });
  }
}
