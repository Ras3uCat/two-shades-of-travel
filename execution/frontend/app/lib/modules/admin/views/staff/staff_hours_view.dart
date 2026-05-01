import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../admin_shell.dart';

class StaffHoursView extends StatefulWidget {
  const StaffHoursView({super.key});

  @override
  State<StaffHoursView> createState() => _StaffHoursViewState();
}

class _StaffHoursViewState extends State<StaffHoursView> {
  final _db = Supabase.instance.client;

  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  bool _loading = true;
  bool _saving  = false;

  // Indexed 0 (Mon) – 6 (Sun). Values from business_hours (fallback) merged with staff_hours.
  final List<bool>   _isClosed  = List.filled(7, false);
  final List<String> _openTime  = List.filled(7, '09:00');
  final List<String> _closeTime = List.filled(7, '17:00');

  // Tracks which weekdays staff has their own overriding row.
  final List<bool> _hasCustom = List.filled(7, false);

  // Controllers for text fields.
  late final List<TextEditingController> _openCtrl;
  late final List<TextEditingController> _closeCtrl;

  @override
  void initState() {
    super.initState();
    _openCtrl  = List.generate(7, (_) => TextEditingController());
    _closeCtrl = List.generate(7, (_) => TextEditingController());
    _load();
  }

  @override
  void dispose() {
    for (final c in _openCtrl)  { c.dispose(); }
    for (final c in _closeCtrl) { c.dispose(); }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;

      final results = await Future.wait([
        _db.from('business_hours').select().order('weekday'),
        _db.from('staff_hours').select().eq('artist_id', uid).order('weekday'),
      ]);

      final bizRows   = List<Map<String, dynamic>>.from(results[0] as List);
      final staffRows = List<Map<String, dynamic>>.from(results[1] as List);

      // Map weekday (1=Mon…7=Sun) → index 0–6.
      final bizMap   = { for (final r in bizRows)   (r['weekday'] as int) - 1: r };
      final staffMap = { for (final r in staffRows) (r['weekday'] as int) - 1: r };

      for (int i = 0; i < 7; i++) {
        final source = staffMap[i] ?? bizMap[i];
        _hasCustom[i]  = staffMap.containsKey(i);
        _isClosed[i]   = (source?['is_closed'] as bool?) ?? false;
        _openTime[i]   = source?['open_time']  as String? ?? '09:00';
        _closeTime[i]  = source?['close_time'] as String? ?? '17:00';
        _openCtrl[i].text  = _openTime[i];
        _closeCtrl[i].text = _closeTime[i];
      }

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAll() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final rows = <Map<String, dynamic>>[];
      for (int i = 0; i < 7; i++) {
        rows.add({
          'artist_id':  uid,
          'weekday':    i + 1,
          'is_closed':  _isClosed[i],
          'open_time':  _openCtrl[i].text.trim().isEmpty ? '09:00' : _openCtrl[i].text.trim(),
          'close_time': _closeCtrl[i].text.trim().isEmpty ? '17:00' : _closeCtrl[i].text.trim(),
        });
      }
      await _db.from('staff_hours').upsert(rows, onConflict: 'artist_id,weekday');
      for (int i = 0; i < 7; i++) { _hasCustom[i] = true; }
      if (mounted) {
        setState(() => _saving = false);
        Get.snackbar('Saved', 'Your hours have been saved.',
            backgroundColor: EColors.primary, colorText: EColors.white, duration: const Duration(seconds: 2));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        Get.snackbar('Error', 'Failed to save hours.',
            backgroundColor: EColors.error, colorText: EColors.white);
      }
    }
  }

  Future<void> _resetRow(int i) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _db.from('staff_hours').delete().eq('artist_id', uid).eq('weekday', i + 1);
      if (mounted) setState(() => _hasCustom[i] = false);
      await _load();
    } catch (_) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to reset.', backgroundColor: EColors.error, colorText: EColors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.staffHours,
      isMaster: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESpacing.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
            ),
            child: Text('My Hours', style: ETextStyles.h2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESpacing.lg, vertical: ESpacing.sm),
            child: Text(
              'Override global business hours for specific days. Use HH:MM format (e.g. 09:00).',
              style: ETextStyles.bodySmMuted,
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: ESpacing.lg, vertical: ESpacing.sm),
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
                itemBuilder: (_, i) => _DayRow(
                  dayName:    _dayNames[i],
                  isClosed:   _isClosed[i],
                  hasCustom:  _hasCustom[i],
                  openCtrl:   _openCtrl[i],
                  closeCtrl:  _closeCtrl[i],
                  onClosedChanged: (v) => setState(() => _isClosed[i] = v),
                  onReset: () => _resetRow(i),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColors.primary,
                    foregroundColor: EColors.white,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
                  ),
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('SAVE ALL', style: ETextStyles.button),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.dayName,
    required this.isClosed,
    required this.hasCustom,
    required this.openCtrl,
    required this.closeCtrl,
    required this.onClosedChanged,
    required this.onReset,
  });

  final String dayName;
  final bool isClosed;
  final bool hasCustom;
  final TextEditingController openCtrl;
  final TextEditingController closeCtrl;
  final ValueChanged<bool> onClosedChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(dayName, style: ETextStyles.h4),
            const Spacer(),
            if (hasCustom)
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: Text('Reset to default', style: ETextStyles.bodySm.copyWith(color: EColors.primary)),
              ),
          ]),
          const SizedBox(height: ESpacing.sm),
          Row(children: [
            Text('Closed', style: ETextStyles.bodySm.copyWith(color: EColors.onSurfaceMuted)),
            const SizedBox(width: ESpacing.sm),
            Switch(
              value: isClosed,
              activeTrackColor: EColors.error,
              onChanged: onClosedChanged,
            ),
            if (!isClosed) ...[
              const Spacer(),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: openCtrl,
                  style: ETextStyles.inputText,
                  decoration: InputDecoration(
                    labelText: 'Open',
                    labelStyle: ETextStyles.inputLabel,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: ESpacing.sm),
              Text('–', style: ETextStyles.body),
              const SizedBox(width: ESpacing.sm),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: closeCtrl,
                  style: ETextStyles.inputText,
                  decoration: InputDecoration(
                    labelText: 'Close',
                    labelStyle: ETextStyles.inputLabel,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}
