import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_env.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

class RecurringDialog extends StatefulWidget {
  const RecurringDialog({super.key, required this.booking});
  final BookingModel booking;

  @override
  State<RecurringDialog> createState() => _RecurringDialogState();
}

class _RecurringDialogState extends State<RecurringDialog> {
  static const _intervals = [14, 21, 28, 42, 56];
  static const _labels    = ['2 wks', '3 wks', '4 wks', '6 wks', '8 wks'];

  int _intervalDays = 28;
  DateTime? _endDate;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  bool get _useStripe =>
      AppEnv.stripeMode != 'none' && AppEnv.stripePk.isNotEmpty;

  List<DateTime> get _previewDates {
    if (_endDate == null) return [];
    final dates = <DateTime>[];
    var d = widget.booking.startTime.add(Duration(days: _intervalDays));
    final end = _endDate!.add(const Duration(days: 1));
    while (d.isBefore(end) && dates.length < 12) {
      dates.add(d);
      d = d.add(Duration(days: _intervalDays));
    }
    return dates;
  }

  Future<void> _pickEndDate() async {
    final min = widget.booking.startTime.add(Duration(days: _intervalDays + 1));
    final initial = _endDate ?? widget.booking.startTime.add(Duration(days: _intervalDays * 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(min) ? min : initial,
      firstDate: min,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null && mounted) setState(() => _endDate = picked);
  }

  Future<void> _confirm() async {
    if (_endDate == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final repo = Get.find<BookingRepository>();
      final result = await repo.createRecurringSeries(
        templateBookingId: widget.booking.id,
        intervalDays:      _intervalDays,
        endDate:           _endDate!,
        confirmed:         !_useStripe,
      );
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not create recurring series. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ESpacing.xl),
          child: _result != null ? _buildResult() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final created   = (_result!['created'] as num).toInt();
    final conflicts = (_result!['conflicts'] as List).cast<String>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Icon(Icons.repeat, color: EColors.primary, size: 24),
          const SizedBox(width: ESpacing.sm),
          Text('Series created', style: ETextStyles.h4),
        ]),
        const SizedBox(height: ESpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ESpacing.md),
          color: EColors.primary.withValues(alpha: 0.08),
          child: Text(
            '$created booking${created == 1 ? '' : 's'} scheduled',
            style: ETextStyles.body,
          ),
        ),
        if (conflicts.isNotEmpty) ...[
          const SizedBox(height: ESpacing.md),
          Text(
            '${conflicts.length} date${conflicts.length == 1 ? '' : 's'} unavailable (conflicts):',
            style: ETextStyles.bodySm.copyWith(color: EColors.error),
          ),
          const SizedBox(height: ESpacing.xs),
          ...conflicts.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('· $d', style: ETextStyles.bodySmMuted),
          )),
        ],
        const SizedBox(height: ESpacing.lg),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CLOSE', style: ETextStyles.button),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final preview = _previewDates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Icon(Icons.repeat, color: EColors.primary, size: 24),
          const SizedBox(width: ESpacing.sm),
          Text('Set up recurring', style: ETextStyles.h4),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: EColors.onSurfaceMuted),
          ),
        ]),
        const SizedBox(height: ESpacing.lg),
        Text('Repeat every', style: ETextStyles.label),
        const SizedBox(height: ESpacing.sm),
        Wrap(
          spacing: ESpacing.xs,
          children: List.generate(_intervals.length, (i) {
            final selected = _intervals[i] == _intervalDays;
            return ChoiceChip(
              label: Text(_labels[i]),
              selected: selected,
              onSelected: (_) => setState(() {
                _intervalDays = _intervals[i];
                // Reset end date if it's now before the new minimum
                if (_endDate != null) {
                  final min = widget.booking.startTime.add(Duration(days: _intervalDays + 1));
                  if (_endDate!.isBefore(min)) _endDate = null;
                }
              }),
              selectedColor: EColors.primary.withValues(alpha: 0.15),
              labelStyle: ETextStyles.bodySm.copyWith(
                color: selected ? EColors.primary : EColors.onSurface,
              ),
            );
          }),
        ),
        const SizedBox(height: ESpacing.lg),
        Text('End date', style: ETextStyles.label),
        const SizedBox(height: ESpacing.xs),
        TextButton.icon(
          onPressed: _pickEndDate,
          icon: Icon(Icons.calendar_today_outlined, size: 16,
              color: EColors.primary),
          label: Text(
            _endDate != null
                ? DateFormat('MMM d, yyyy').format(_endDate!)
                : 'Pick a date',
            style: ETextStyles.body.copyWith(color: EColors.primary),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        if (preview.isNotEmpty) ...[
          const SizedBox(height: ESpacing.lg),
          Text('Upcoming dates (preview)', style: ETextStyles.label),
          const SizedBox(height: ESpacing.xs),
          ...preview.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              DateFormat('EEE, MMM d, yyyy').format(d),
              style: ETextStyles.bodySmMuted,
            ),
          )),
          if (_previewDates.length == 12)
            Text('(showing first 12)', style: ETextStyles.bodySmMuted),
        ],
        if (_error != null) ...[
          const SizedBox(height: ESpacing.md),
          Text(_error!, style: ETextStyles.bodySm.copyWith(color: EColors.error)),
        ],
        const SizedBox(height: ESpacing.xl),
        if (_useStripe)
          Padding(
            padding: const EdgeInsets.only(bottom: ESpacing.md),
            child: Text(
              'You\'ll receive a payment link before each appointment.',
              style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_endDate == null || _loading) ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.secondary,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
            ),
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('CONFIRM', style: ETextStyles.button),
          ),
        ),
      ],
    );
  }
}
