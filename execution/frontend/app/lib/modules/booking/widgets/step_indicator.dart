import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/booking_controller.dart';

class StepIndicator extends GetView<BookingController> {
  const StepIndicator({super.key});

  static const _labels = ['ARTIST', 'SERVICES', 'TIME', 'CONFIRM'];

  @override
  Widget build(BuildContext context) {
    final connectorW =
        MediaQuery.sizeOf(context).width < ESpacing.mobileBreak ? 24.0 : 48.0;
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_labels.length * 2 - 1, (i) {
            if (i.isOdd) {
              return _connector(i ~/ 2, controller.currentStep.value, connectorW);
            }
            return _dot(i ~/ 2, controller.currentStep.value);
          }),
        ));
  }

  Widget _dot(int step, int current) {
    final isDone   = step < current;
    final isActive = step == current;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28.0,
      height: 28.0,
      decoration: BoxDecoration(
        color: isActive
            ? EColors.primary
            : isDone
                ? EColors.primaryMedium
                : EColors.surfaceVariant,
        border: Border.all(
          color: isActive || isDone ? EColors.primary : EColors.divider,
          width: 0.5,
        ),
      ),
      child: Center(
        child: isDone
            ? Icon(Icons.check, color: EColors.primary, size: 14)
            : Text(
                '${step + 1}',
                style: ETextStyles.labelSm.copyWith(
                  color: isActive ? EColors.secondary : EColors.onSurfaceMuted,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }

  Widget _connector(int afterStep, int current, double width) {
    final isPassed = afterStep < current;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      height: 0.5,
      color: isPassed ? EColors.primary : EColors.divider,
    );
  }
}
