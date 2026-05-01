import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/gdpr_controller.dart';

/// Full-screen overlay widget — place as a child of a Stack (e.g. in
/// GetMaterialApp.builder). Aligns the cookie banner to the bottom.
/// Collapses to SizedBox.shrink() once the user responds.
class GdprBanner extends GetView<GdprController> {
  const GdprBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.hasResponded) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          elevation: 8,
          color: EColors.surface,
          child: SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: ESpacing.lg, vertical: ESpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: EColors.surfaceVariant, width: 1),
                ),
              ),
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final isNarrow = constraints.maxWidth < 520;
                  final message = Text(
                    'We use cookies to improve your experience on this site. '
                    'You can accept or decline non-essential cookies.',
                    style: ETextStyles.bodyMd.copyWith(fontSize: 13),
                  );
                  final actions = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: controller.decline,
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: ESpacing.sm),
                      ElevatedButton(
                        onPressed: controller.accept,
                        child: const Text('Accept'),
                      ),
                    ],
                  );
                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        message,
                        const SizedBox(height: ESpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: actions,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: message),
                      const SizedBox(width: ESpacing.lg),
                      actions,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }
}
