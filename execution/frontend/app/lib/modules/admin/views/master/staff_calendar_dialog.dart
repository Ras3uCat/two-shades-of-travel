import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/master_controller.dart';

/// Admin dialog for viewing or regenerating a staff member's calendar token.
class StaffCalendarDialog extends StatefulWidget {
  const StaffCalendarDialog({
    super.key,
    required this.staffId,
    required this.staffName,
  });
  final String staffId;
  final String staffName;

  @override
  State<StaffCalendarDialog> createState() => _StaffCalendarDialogState();
}

class _StaffCalendarDialogState extends State<StaffCalendarDialog> {
  String? _token;
  bool    _loading = true;
  bool    _regenerating = false;

  String _feedUrl(String token) =>
      '${AppEnv.supabaseUrl}/functions/v1/staff-calendar?token=$token';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await Get.find<MasterController>()
          .getStaffCalendarToken(widget.staffId);
      if (mounted) setState(() { _token = token; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);
    try {
      final token = await Get.find<MasterController>()
          .regenerateStaffCalendarToken(widget.staffId);
      if (mounted) setState(() => _token = token);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to regenerate token.')),
        );
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  void _copy() {
    if (_token == null) return;
    Clipboard.setData(ClipboardData(text: _feedUrl(_token!)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calendar URL copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(ESpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calendar Feed', style: ETextStyles.h3),
                      Text(widget.staffName, style: ETextStyles.bodyMuted),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ]),
              const SizedBox(height: ESpacing.lg),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_token == null)
                Text('No token yet — generate one below.',
                    style: ETextStyles.bodyMuted)
              else ...[
                Text('Feed URL', style: ETextStyles.label),
                const SizedBox(height: ESpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ESpacing.sm),
                  decoration: BoxDecoration(
                    color:  EColors.surfaceVariant,
                    border: Border.all(color: EColors.divider),
                  ),
                  child: SelectableText(
                    _feedUrl(_token!),
                    style: ETextStyles.caption
                        .copyWith(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: ESpacing.sm),
                TextButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 14),
                  label: Text('Copy URL', style: ETextStyles.labelSm),
                  style: TextButton.styleFrom(
                    foregroundColor: EColors.primary,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
              const SizedBox(height: ESpacing.lg),
              if (_token != null)
                Text(
                  'Regenerating breaks existing calendar subscriptions.',
                  style: ETextStyles.caption
                      .copyWith(color: EColors.onSurfaceMuted),
                ),
              const SizedBox(height: ESpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _regenerating ? null : _regenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColors.primary,
                    foregroundColor: EColors.secondary,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
                  ),
                  child: _regenerating
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          _token == null ? 'Generate Token' : 'Regenerate Token',
                          style: ETextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
