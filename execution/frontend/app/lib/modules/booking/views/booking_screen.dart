import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_env.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../modules/location/location_selector_step.dart';
import '../controllers/booking_controller.dart';
import '../widgets/step_indicator.dart';
import '../widgets/step1_artist_selection.dart';
import '../widgets/step2_service_selection.dart';
import '../widgets/step3_time_slot_picker.dart';
import '../widgets/step4_confirmation_summary.dart';

class BookingScreen extends GetView<BookingController> {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Support deep-link pre-selection: /booking?artistId=xxx
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      final preselectedId = args['preselectedArtistId'] as String?;
      if (preselectedId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final artist = controller.artists
              .firstWhereOrNull((a) => a.id == preselectedId);
          if (artist != null) controller.selectArtist(artist);
        });
      }
    }

    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: _BookingAppBar(),
      body: Obx(() {
        // Location pre-step: shown before the booking flow when LOCATIONS_ENABLED=true.
        if (AppEnv.locationsEnabled &&
            controller.selectedLocationId.value == null) {
          return LocationSelectorStep(
            onSelected: (loc) => controller.selectLocation(loc.id),
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: IndexedStack(
            key: ValueKey(controller.currentStep.value),
            index: controller.currentStep.value,
            children: const [
              Step1ArtistSelection(),
              Step2ServiceSelection(),
              Step3TimeSlotPicker(),
              Step4ConfirmationSummary(),
            ],
          ),
        );
      }),
    );
  }
}

class _BookingAppBar extends GetView<BookingController>
    implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: EColors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + ESpacing.md,
        bottom: ESpacing.md,
        left: ESpacing.lg,
        right: ESpacing.lg,
      ),
      child: Row(
        children: [
          Obx(() => controller.currentStep.value > 0
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: controller.goBack,
                    child: Row(children: [
                      Icon(Icons.arrow_back_ios,
                          color: EColors.onSurface, size: 16),
                      const SizedBox(width: ESpacing.xs),
                      Text('BACK',
                          style: ETextStyles.label.copyWith(
                              color: EColors.onSurfaceMuted)),
                    ]),
                  ),
                )
              : const SizedBox(width: 48)),
          const Spacer(),
          const StepIndicator(),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: controller.closeBooking,
              child: Icon(Icons.close,
                  color: EColors.onSurfaceMuted, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
