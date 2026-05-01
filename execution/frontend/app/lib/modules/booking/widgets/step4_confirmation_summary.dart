import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/booking_controller.dart';
import 'booking_summary_card.dart';
import 'client_form.dart';

class Step4ConfirmationSummary extends GetView<BookingController> {
  const Step4ConfirmationSummary({super.key});

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
              Text('STEP 04', style: ETextStyles.overline),
              const SizedBox(height: ESpacing.sm),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: ESpacing.md),
              Text('CONFIRM & BOOK', style: ETextStyles.h2),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: ESpacing.md),
            child: isMobile
                ? Column(children: [
                    const BookingSummaryCard(),
                    const SizedBox(height: ESpacing.xl),
                    const ClientForm(),
                  ])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: BookingSummaryCard()),
                      const SizedBox(width: ESpacing.xl),
                      const Expanded(child: ClientForm()),
                    ],
                  ),
          ),
        ),
        Obx(() {
          if (controller.error.value != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ESpacing.lg, vertical: ESpacing.sm),
              child: Text(
                controller.error.value!,
                style: ETextStyles.bodySm.copyWith(color: EColors.error),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        const _ConfirmBar(),
      ],
    );
  }
}

class _ConfirmBar extends GetView<BookingController> {
  const _ConfirmBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.lg, vertical: ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border(
            top: BorderSide(color: EColors.divider, width: 0.5)),
      ),
      child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (controller.isConfirming.value)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                AnimatedOpacity(
                  opacity: controller.canConfirm ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 250),
                  child: ElevatedButton(
                    onPressed: controller.canConfirm
                        ? () => controller.confirmBooking()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EColors.primary,
                      foregroundColor: EColors.secondary,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: ESpacing.xl, vertical: ESpacing.md),
                    ),
                    child: Text('CONFIRM BOOKING', style: ETextStyles.button),
                  ),
                ),
            ],
          )),
    );
  }
}
