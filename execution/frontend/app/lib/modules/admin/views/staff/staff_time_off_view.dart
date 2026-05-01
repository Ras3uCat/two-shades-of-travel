import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/staff_controller.dart';
import '../admin_shell.dart';

class StaffTimeOffView extends GetView<StaffController> {
  const StaffTimeOffView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.staffTimeOff,
      isMaster: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESpacing.lg),
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
            ),
            child: Row(children: [
              Text('Time Off', style: ETextStyles.h2),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text('ADD', style: ETextStyles.button),
                onPressed: () => _showAddDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: EColors.secondary,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final blocks = controller.timeOff;
              if (blocks.isEmpty) {
                return Center(
                    child: Text('No upcoming time off.',
                        style: ETextStyles.bodyMuted));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(ESpacing.lg),
                itemCount: blocks.length,
                separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
                itemBuilder: (_, i) => _TimeOffTile(block: blocks[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    DateTime? start;
    DateTime? end;
    final reasonCtrl = TextEditingController();
    final fmt = DateFormat('MMM d, yyyy h:mm a');

    Get.dialog(StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: EColors.surface,
        title: Text('Add Time Off', style: ETextStyles.h3),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DatePickerRow(
                label: 'Start',
                value: start != null ? fmt.format(start!) : 'Select…',
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null && ctx.mounted) {
                    final t = await showTimePicker(
                        context: ctx, initialTime: TimeOfDay.now());
                    if (t != null) {
                      setState(() => start = DateTime(
                          d.year, d.month, d.day, t.hour, t.minute));
                    }
                  }
                },
              ),
              const SizedBox(height: ESpacing.md),
              _DatePickerRow(
                label: 'End',
                value: end != null ? fmt.format(end!) : 'Select…',
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: start ?? DateTime.now(),
                    firstDate: start ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null && ctx.mounted) {
                    final t = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 17, minute: 0));
                    if (t != null) {
                      setState(() => end = DateTime(
                          d.year, d.month, d.day, t.hour, t.minute));
                    }
                  }
                },
              ),
              const SizedBox(height: ESpacing.md),
              TextField(
                controller: reasonCtrl,
                style: ETextStyles.inputText,
                decoration: InputDecoration(
                  labelText: 'Reason (optional)',
                  labelStyle: ETextStyles.inputLabel,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('CANCEL',
                style: ETextStyles.button.copyWith(
                    color: EColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: (start != null && end != null)
                ? () async {
                    Get.back();
                    final ok = await controller.addTimeOff(
                      start: start!,
                      end: end!,
                      reason: reasonCtrl.text.trim().isEmpty
                          ? null
                          : reasonCtrl.text.trim(),
                    );
                    if (!ok) {
                      Get.snackbar('Error', 'Failed to add time off.',
                          backgroundColor: EColors.error,
                          colorText: EColors.white);
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.secondary,
              shape: const RoundedRectangleBorder(),
            ),
            child: Text('SAVE', style: ETextStyles.button),
          ),
        ],
      ),
    ));
  }
}

class _TimeOffTile extends GetView<StaffController> {
  const _TimeOffTile({required this.block});
  final Map<String, dynamic> block;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(block['start_time'] as String).toLocal();
    final end   = DateTime.parse(block['end_time']   as String).toLocal();
    final fmt   = DateFormat('MMM d, h:mm a');

    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${fmt.format(start)} → ${fmt.format(end)}',
                style: ETextStyles.body),
            if (block['reason'] != null)
              Text(block['reason'] as String,
                  style: ETextStyles.bodySmMuted),
          ]),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline,
              color: EColors.error, size: 18),
          onPressed: () => controller.deleteTimeOff(block['id'] as String),
        ),
      ]),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: ESpacing.md, vertical: ESpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: EColors.divider, width: 0.5),
        ),
        child: Row(children: [
          Text(label,
              style: ETextStyles.label.copyWith(
                  color: EColors.onSurfaceMuted)),
          const Spacer(),
          Text(value, style: ETextStyles.body),
          const SizedBox(width: ESpacing.sm),
          Icon(Icons.chevron_right, color: EColors.onSurfaceMuted, size: 18),
        ]),
      ),
    );
  }
}
