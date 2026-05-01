import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';
import 'business_content_section.dart';
import 'chatbot_config_section.dart';

class BusinessConfigView extends GetView<MasterController> {
  const BusinessConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminConfig,
      isMaster: true,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(ESpacing.lg),
          children: [
            Text('Business Settings', style: ETextStyles.h2),
            const SizedBox(height: ESpacing.xl),
            BusinessContentSection(controller: controller),
            const SizedBox(height: ESpacing.xl),
            _ConfigSection(controller: controller),
            const SizedBox(height: ESpacing.xl),
            _HoursSection(controller: controller),
            if (AppEnv.chatbotFull) ...[
              const SizedBox(height: ESpacing.xl),
              ChatbotConfigSection(controller: controller),
            ],
          ],
        );
      }),
    );
  }
}

class _ConfigSection extends StatefulWidget {
  const _ConfigSection({required this.controller});
  final MasterController controller;

  @override
  State<_ConfigSection> createState() => _ConfigSectionState();
}

class _ConfigSectionState extends State<_ConfigSection> {
  late final TextEditingController _cancelHours;
  late final TextEditingController _cancelRefund;
  late final TextEditingController _buffer;
  late final TextEditingController _interval;
  late final TextEditingController _depositPct;

  @override
  void initState() {
    super.initState();
    final c = widget.controller.config;
    _cancelHours = TextEditingController(
        text: (c['cancellation_hours'] ?? 24).toString());
    _cancelRefund = TextEditingController(
        text: (c['cancellation_refund_pct'] ?? 100).toString());
    _buffer   = TextEditingController(
        text: (c['buffer_minutes'] ?? 0).toString());
    _interval = TextEditingController(
        text: (c['booking_interval_minutes'] ?? 20).toString());
    _depositPct = TextEditingController(
        text: (c['deposit_pct'] ?? 100).toString());
  }

  @override
  void dispose() {
    _cancelHours.dispose();
    _cancelRefund.dispose();
    _buffer.dispose();
    _interval.dispose();
    _depositPct.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Booking Rules', style: ETextStyles.h3),
          const Spacer(),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.secondary,
              shape: const RoundedRectangleBorder(),
            ),
            child: Text('SAVE', style: ETextStyles.button),
          ),
        ]),
        const SizedBox(height: ESpacing.md),
        Row(children: [
          Expanded(child: _NumField(ctrl: _cancelHours,
              label: 'Cancellation window (hrs)')),
          const SizedBox(width: ESpacing.md),
          Expanded(child: _NumField(ctrl: _cancelRefund,
              label: 'Refund on cancel (%)')),
        ]),
        const SizedBox(height: ESpacing.md),
        Row(children: [
          Expanded(child: _NumField(ctrl: _buffer,
              label: 'Buffer between bookings (min)')),
          const SizedBox(width: ESpacing.md),
          Expanded(child: _NumField(ctrl: _interval,
              label: 'Slot interval (min)')),
        ]),
        const SizedBox(height: ESpacing.md),
        Row(children: [
          Expanded(child: _NumField(ctrl: _depositPct,
              label: 'Deposit % (0 = pay at appt, 100 = full now)')),
          const SizedBox(width: ESpacing.md),
          const Expanded(child: SizedBox.shrink()),
        ]),
      ],
    );
  }

  Future<void> _save() async {
    await widget.controller.saveConfig({
      'cancellation_hours':       int.tryParse(_cancelHours.text) ?? 24,
      'cancellation_refund_pct':  int.tryParse(_cancelRefund.text) ?? 100,
      'buffer_minutes':           int.tryParse(_buffer.text) ?? 0,
      'booking_interval_minutes': int.tryParse(_interval.text) ?? 20,
      'deposit_pct':              (int.tryParse(_depositPct.text))?.clamp(0, 100) ?? 100,
    });
    Get.snackbar('Saved', 'Business rules updated.',
        backgroundColor: EColors.primary.withValues(alpha: 0.9),
        colorText: EColors.secondary);
  }
}

class _HoursSection extends StatelessWidget {
  const _HoursSection({required this.controller});
  final MasterController controller;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business Hours', style: ETextStyles.h3),
        const SizedBox(height: ESpacing.md),
        ...List.generate(7, (i) {
          final weekday = i + 1;
          final row = controller.businessHours.firstWhereOrNull(
              (h) => h['weekday'] == weekday);
          if (row == null) return const SizedBox.shrink();
          return _HourRow(
            label: _days[i],
            weekday: weekday,
            row: row,
            controller: controller,
          );
        }),
      ],
    );
  }
}

class _HourRow extends StatefulWidget {
  const _HourRow({
    required this.label,
    required this.weekday,
    required this.row,
    required this.controller,
  });
  final String label;
  final int weekday;
  final Map<String, dynamic> row;
  final MasterController controller;

  @override
  State<_HourRow> createState() => _HourRowState();
}

class _HourRowState extends State<_HourRow> {
  late bool _closed;
  late TextEditingController _open;
  late TextEditingController _close;

  @override
  void initState() {
    super.initState();
    _closed = widget.row['closed'] as bool? ?? false;
    _open   = TextEditingController(
        text: (widget.row['open_time'] as String?)?.substring(0, 5) ?? '09:00');
    _close  = TextEditingController(
        text: (widget.row['close_time'] as String?)?.substring(0, 5) ?? '17:00');
  }

  @override
  void dispose() {
    _open.dispose();
    _close.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESpacing.sm),
      child: Row(children: [
        SizedBox(
          width: 36,
          child: Text(widget.label, style: ETextStyles.label),
        ),
        Switch(
          value: !_closed,
          activeTrackColor: EColors.primary,
          onChanged: (v) => setState(() => _closed = !v),
        ),
        if (!_closed) ...[
          const SizedBox(width: ESpacing.sm),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _open,
              style: ETextStyles.bodySm,
              decoration: InputDecoration(
                isDense: true,
                hintText: '09:00',
                hintStyle: ETextStyles.bodySmMuted,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESpacing.sm),
            child: Text('–', style: ETextStyles.body),
          ),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _close,
              style: ETextStyles.bodySm,
              decoration: InputDecoration(
                isDense: true,
                hintText: '17:00',
                hintStyle: ETextStyles.bodySmMuted,
              ),
            ),
          ),
          const SizedBox(width: ESpacing.md),
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: Text('SAVE',
                style: ETextStyles.labelSm.copyWith(color: EColors.primary)),
          ),
        ],
      ]),
    );
  }

  Future<void> _save() async {
    await widget.controller.saveBusinessHour(widget.weekday, {
      'closed':     _closed,
      'open_time':  _closed ? null : _open.text,
      'close_time': _closed ? null : _close.text,
    });
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.ctrl, required this.label});
  final TextEditingController ctrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: ETextStyles.inputText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ETextStyles.inputLabel,
      ),
    );
  }
}
