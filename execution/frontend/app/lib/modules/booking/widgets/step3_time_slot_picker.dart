import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_env.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/booking_controller.dart';
import 'time_slot_chip.dart';

class Step3TimeSlotPicker extends GetView<BookingController> {
  const Step3TimeSlotPicker({super.key});

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
              Text('STEP 03', style: ETextStyles.overline),
              const SizedBox(height: ESpacing.sm),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: ESpacing.md),
              Text('PICK A TIME', style: ETextStyles.h2),
              const SizedBox(height: ESpacing.sm),
              Obx(() => Text(
                    'Session length: ${controller.formattedTotalDuration}',
                    style: ETextStyles.body.copyWith(color: EColors.primary),
                  )),
            ],
          ),
        ),
        Obx(() {
          if (controller.slotsLoading.value) {
            return const Expanded(
                child: Center(child: CircularProgressIndicator()));
          }
          return Column(
            children: [
              _DateTabs(
                dates: controller.availableDates,
                selectedIndex: controller.selectedDateIndex.value,
                onSelect: controller.selectDate,
              ),
              const SizedBox(height: ESpacing.lg),
            ],
          );
        }),
        Expanded(
          child: Obx(() {
            if (controller.slotsLoading.value) return const SizedBox.shrink();
            final slots = controller.slotsForSelectedDate;
            if (slots.isEmpty) {
              return controller.availableSlots.isEmpty
                  ? _NoAvailability(hPad: hPad, controller: controller)
                  : _EmptyDay(hPad: hPad);
            }
            return _SlotGrid(
              slots: slots,
              controller: controller,
              hPad: hPad,
              isMobile: isMobile,
            );
          }),
        ),
        Obx(() => _BottomBar(
              canContinue: controller.canProceedStep3,
              onContinue: controller.proceedFromStep3,
            )),
      ],
    );
  }
}

class _DateTabs extends StatelessWidget {
  const _DateTabs({
    required this.dates,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<DateTime> dates;
  final int selectedIndex;
  final Function(int) onSelect;

  static const _dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: ESpacing.lg),
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: ESpacing.sm),
        itemBuilder: (_, i) {
          final isSelected = i == selectedIndex;
          final date = dates[i];
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected ? EColors.primary : EColors.surfaceVariant,
                border: Border.all(
                  color: isSelected ? EColors.primary : EColors.divider,
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayNames[date.weekday - 1],
                    style: ETextStyles.labelSm.copyWith(
                      color: isSelected
                          ? EColors.secondary
                          : EColors.onSurfaceMuted,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: ETextStyles.h3.copyWith(
                      color: isSelected ? EColors.secondary : EColors.onSurface,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.slots,
    required this.controller,
    required this.hPad,
    required this.isMobile,
  });

  final List<dynamic> slots;
  final BookingController controller;
  final double hPad;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: ESpacing.md,
        mainAxisSpacing: ESpacing.md,
        childAspectRatio: 2.2,
      ),
      itemCount: slots.length,
      itemBuilder: (_, i) => Obx(() => TimeSlotChip(
            slot: slots[i],
            isSelected: controller.selectedSlot.value?.id == slots[i].id,
            onTap: () => controller.selectSlot(slots[i]),
          )),
    );
  }
}

// Shown when a selected date has no slots but other dates do
class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.hPad});
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, color: EColors.divider, size: 48),
          const SizedBox(height: ESpacing.md),
          Text('No slots available on this day.',
              style: ETextStyles.bodyMuted),
          const SizedBox(height: ESpacing.sm),
          Text('Try another date above.',
              style: ETextStyles.bodySmMuted),
        ],
      ),
    );
  }
}

// Shown when there are zero slots in the next 14 days
class _NoAvailability extends StatelessWidget {
  const _NoAvailability({required this.hPad, required this.controller});
  final double hPad;
  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: ESpacing.lg),
      child: Obx(() {
        if (controller.waitlistSubmitted.value) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 56, color: EColors.primary),
              const SizedBox(height: ESpacing.md),
              Text("You're on the list!", style: ETextStyles.h3),
              const SizedBox(height: ESpacing.sm),
              Text(
                "We'll email you as soon as a slot opens up.",
                style: ETextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.event_busy_outlined,
                  color: EColors.divider, size: 36),
              const SizedBox(width: ESpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No availability in the next 14 days.',
                        style: ETextStyles.body),
                    Text('Try reducing services or picking another artist.',
                        style: ETextStyles.bodySmMuted),
                  ],
                ),
              ),
            ]),
            if (AppEnv.waitlistEnabled) ...[
              const SizedBox(height: ESpacing.xl),
              Divider(color: EColors.divider, thickness: 0.5, height: 1),
              const SizedBox(height: ESpacing.lg),
              Text('JOIN THE WAITLIST', style: ETextStyles.label),
              const SizedBox(height: ESpacing.xs),
              Text(
                "We'll notify you by email when a slot opens up.",
                style: ETextStyles.bodySmMuted,
              ),
              const SizedBox(height: ESpacing.md),
              _WaitlistForm(controller: controller),
            ],
          ],
        );
      }),
    );
  }
}

class _WaitlistForm extends StatefulWidget {
  const _WaitlistForm({required this.controller});
  final BookingController controller;

  @override
  State<_WaitlistForm> createState() => _WaitlistFormState();
}

class _WaitlistFormState extends State<_WaitlistForm> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameCtrl,
          style: ETextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'FULL NAME',
            labelStyle: ETextStyles.inputLabel,
          ),
        ),
        const SizedBox(height: ESpacing.md),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: ETextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'EMAIL',
            labelStyle: ETextStyles.inputLabel,
          ),
        ),
        const SizedBox(height: ESpacing.lg),
        Obx(() {
          if (widget.controller.waitlistError.value != null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: ESpacing.sm),
              child: Text(widget.controller.waitlistError.value!,
                  style: ETextStyles.bodySm.copyWith(color: EColors.error)),
            );
          }
          return const SizedBox.shrink();
        }),
        Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.controller.isJoiningWaitlist.value
                    ? null
                    : () => widget.controller.joinWaitlist(
                          name:  _nameCtrl.text,
                          email: _emailCtrl.text,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: EColors.secondary,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(
                      vertical: ESpacing.md),
                ),
                child: widget.controller.isJoiningWaitlist.value
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('NOTIFY ME', style: ETextStyles.button),
              ),
            )),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.canContinue, required this.onContinue});
  final bool canContinue;
  final VoidCallback onContinue;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
      ),
    );
  }
}
