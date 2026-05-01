import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/booking_controller.dart';

class DurationTotalBar extends GetView<BookingController> {
  const DurationTotalBar({
    super.key,
    required this.onContinue,
    required this.canContinue,
  });

  final VoidCallback onContinue;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.0,
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border(
          top: BorderSide(color: EColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: ESpacing.lg),
      child: Obx(() => Row(
            children: [
              Text(
                '${controller.selectedServiceIds.length} '
                'SERVICE${controller.selectedServiceIds.length == 1 ? '' : 'S'}',
                style: ETextStyles.label.copyWith(color: EColors.onSurfaceMuted),
              ),
              const SizedBox(width: ESpacing.lg),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  controller.formattedTotalDuration,
                  key: ValueKey(controller.formattedTotalDuration),
                  style: ETextStyles.h4.copyWith(color: EColors.primary),
                ),
              ),
              const SizedBox(width: ESpacing.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  controller.selectedServiceIds.isEmpty
                      ? ''
                      : '\$${controller.totalPrice.toStringAsFixed(0)}',
                  key: ValueKey(controller.totalPrice),
                  style: ETextStyles.body.copyWith(
                      color: EColors.onSurfaceMuted),
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: canContinue ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 250),
                child: ElevatedButton(
                  onPressed: canContinue ? onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColors.primary,
                    foregroundColor: EColors.secondary,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: ESpacing.xl, vertical: ESpacing.md),
                  ),
                  child: Text('CONTINUE', style: ETextStyles.button),
                ),
              ),
            ],
          )),
    );
  }
}
