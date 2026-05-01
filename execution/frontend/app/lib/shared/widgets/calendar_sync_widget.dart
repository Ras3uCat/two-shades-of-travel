import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_env.dart';
import '../../core/theme/e_colors.dart';
import '../../core/theme/e_spacing.dart';
import '../../core/theme/e_text_styles.dart';
import '../../modules/admin/controllers/staff_controller.dart';

/// Embedded in the staff portal — shows the iCal subscribe URL, a copy
/// button, a Google Calendar shortcut, and a token regeneration option.
class CalendarSyncWidget extends StatelessWidget {
  const CalendarSyncWidget({super.key});

  String _feedUrl(String token) =>
      '${AppEnv.supabaseUrl}/functions/v1/staff-calendar?token=$token';

  Uri _gcalUri(String token) => Uri.parse(
      'https://calendar.google.com/calendar/r/settings/addbyurl'
      '?url=${Uri.encodeComponent(_feedUrl(token))}');

  void _copy(BuildContext context, String token) {
    Clipboard.setData(ClipboardData(text: _feedUrl(token)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calendar URL copied!')),
    );
  }

  Future<void> _openGcal(String token) async {
    final uri = _gcalUri(token);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _confirmRegenerate(BuildContext context, StaffController ctrl) {
    Get.dialog(AlertDialog(
      backgroundColor: EColors.surface,
      title: Text('Regenerate token?', style: ETextStyles.h3),
      content: Text(
        'Your existing calendar subscriptions will stop updating. '
        'You will need to re-subscribe with the new URL.',
        style: ETextStyles.body,
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text('Cancel', style: ETextStyles.label),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.regenerateCalendarToken();
          },
          child: Text('Regenerate',
              style: ETextStyles.label.copyWith(color: EColors.error)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StaffController>();
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.all(ESpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 18, color: EColors.primary),
            const SizedBox(width: ESpacing.sm),
            Text('Subscribe to Calendar', style: ETextStyles.h4),
          ]),
          const SizedBox(height: ESpacing.xs),
          Text(
            'Add your bookings to Google Calendar, Apple Calendar, or Outlook.',
            style: ETextStyles.bodySmMuted,
          ),
          const SizedBox(height: ESpacing.md),
          Obx(() {
            if (ctrl.isCalendarLoading.value) {
              return const LinearProgressIndicator();
            }
            final token = ctrl.calendarToken.value;
            if (token == null) {
              return Text('Unable to load calendar URL.',
                  style: ETextStyles.bodySmMuted);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: ESpacing.md, vertical: ESpacing.sm),
                  decoration: BoxDecoration(
                    color:  EColors.surfaceVariant,
                    border: Border.all(color: EColors.divider),
                  ),
                  child: SelectableText(
                    _feedUrl(token),
                    style: ETextStyles.caption
                        .copyWith(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: ESpacing.sm),
                Wrap(
                  spacing: ESpacing.sm,
                  runSpacing: ESpacing.xs,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _copy(context, token),
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy URL'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EColors.primary,
                        side: BorderSide(color: EColors.primary),
                        textStyle: ETextStyles.labelSm,
                        padding: const EdgeInsets.symmetric(
                            horizontal: ESpacing.md, vertical: ESpacing.xs),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openGcal(token),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Google Calendar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EColors.onSurfaceMuted,
                        side: BorderSide(color: EColors.divider),
                        textStyle: ETextStyles.labelSm,
                        padding: const EdgeInsets.symmetric(
                            horizontal: ESpacing.md, vertical: ESpacing.xs),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _confirmRegenerate(context, ctrl),
                      style: TextButton.styleFrom(
                        foregroundColor: EColors.onSurfaceMuted,
                        textStyle: ETextStyles.labelSm,
                        padding: const EdgeInsets.symmetric(
                            horizontal: ESpacing.sm, vertical: ESpacing.xs),
                      ),
                      child: const Text('Regenerate token'),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
