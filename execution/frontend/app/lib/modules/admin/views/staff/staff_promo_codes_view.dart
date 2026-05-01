import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/staff_controller.dart';
import '../admin_shell.dart';

class StaffPromoCodesView extends GetView<StaffController> {
  const StaffPromoCodesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.staffPromoCodes,
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
              Text('Promo Codes', style: ETextStyles.h2),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text('NEW CODE', style: ETextStyles.button),
                onPressed: () => _showCreateDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: EColors.secondary,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: ESpacing.lg, vertical: ESpacing.sm),
            child: Text(
              'Promo codes are valid only on bookings assigned to you.',
              style: ETextStyles.bodySmMuted,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final codes = controller.promoCodes;
              if (codes.isEmpty) {
                return Center(
                    child: Text('No promo codes yet.',
                        style: ETextStyles.bodyMuted));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(ESpacing.lg),
                itemCount: codes.length,
                separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
                itemBuilder: (_, i) => _PromoTile(code: codes[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final codeCtrl    = TextEditingController();
    final valueCtrl   = TextEditingController();
    final maxUsesCtrl = TextEditingController();
    String discountType = 'percent';
    DateTime? expiresAt;

    Get.dialog(StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: EColors.surface,
        title: Text('New Promo Code', style: ETextStyles.h3),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                style: ETextStyles.inputText,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'CODE (e.g. RYAN20)',
                  labelStyle: ETextStyles.inputLabel,
                ),
              ),
              const SizedBox(height: ESpacing.md),
              Row(children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Type',
                      labelStyle: ETextStyles.inputLabel,
                    ),
                    child: DropdownButton<String>(
                      value: discountType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: ETextStyles.inputText,
                      items: const [
                        DropdownMenuItem(value: 'percent', child: Text('Percent')),
                        DropdownMenuItem(value: 'fixed',   child: Text('Fixed \$')),
                      ],
                      onChanged: (v) => setState(() => discountType = v!),
                    ),
                  ),
                ),
                const SizedBox(width: ESpacing.md),
                Expanded(
                  child: TextField(
                    controller: valueCtrl,
                    keyboardType: TextInputType.number,
                    style: ETextStyles.inputText,
                    decoration: InputDecoration(
                      labelText: discountType == 'percent' ? 'Value (%)' : 'Value (\$)',
                      labelStyle: ETextStyles.inputLabel,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: ESpacing.md),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: maxUsesCtrl,
                    keyboardType: TextInputType.number,
                    style: ETextStyles.inputText,
                    decoration: InputDecoration(
                      labelText: 'Max uses (blank = unlimited)',
                      labelStyle: ETextStyles.inputLabel,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: ESpacing.sm),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (d != null) setState(() => expiresAt = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ESpacing.md, vertical: ESpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: EColors.divider, width: 0.5),
                  ),
                  child: Row(children: [
                    Text('Expires',
                        style: ETextStyles.label.copyWith(
                            color: EColors.onSurfaceMuted)),
                    const Spacer(),
                    Text(
                      expiresAt != null
                          ? DateFormat('MMM d, yyyy').format(expiresAt!)
                          : 'Never',
                      style: ETextStyles.body,
                    ),
                    const SizedBox(width: ESpacing.sm),
                    Icon(Icons.chevron_right,
                        color: EColors.onSurfaceMuted, size: 18),
                  ]),
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
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty || valueCtrl.text.trim().isEmpty) {
                return;
              }
              Get.back();
              final ok = await controller.createPromoCode(
                code:         codeCtrl.text,
                discountType: discountType,
                discountValue: double.tryParse(valueCtrl.text) ?? 0,
                maxUses:
                    maxUsesCtrl.text.isEmpty ? null : int.tryParse(maxUsesCtrl.text),
                expiresAt: expiresAt,
              );
              if (!ok) {
                Get.snackbar('Error', 'Code may already exist.',
                    backgroundColor: EColors.error,
                    colorText: EColors.white);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.secondary,
              shape: const RoundedRectangleBorder(),
            ),
            child: Text('CREATE', style: ETextStyles.button),
          ),
        ],
      ),
    ));
  }
}

class _PromoTile extends GetView<StaffController> {
  const _PromoTile({required this.code});
  final Map<String, dynamic> code;

  @override
  Widget build(BuildContext context) {
    final isActive  = code['is_active'] as bool? ?? true;
    final usesCount = code['uses_count'] as int? ?? 0;
    final maxUses   = code['max_uses'] as int?;
    final expiresAt = code['expires_at'] as String?;
    final type      = code['discount_type'] as String? ?? 'percent';
    final value     = (code['discount_value'] as num?)?.toDouble() ?? 0.0;
    final label     = type == 'percent'
        ? '${value.toStringAsFixed(0)}% off'
        : '\$${value.toStringAsFixed(0)} off';

    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(
          color: isActive ? EColors.divider : EColors.divider.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              code['code'] as String? ?? '',
              style: ETextStyles.h4.copyWith(
                fontFamily: 'monospace',
                color: isActive ? EColors.primary : EColors.onSurfaceMuted,
              ),
            ),
            Text(
              '$label · $usesCount${maxUses != null ? '/$maxUses' : ''} uses'
              '${expiresAt != null ? ' · expires ${DateFormat('MMM d').format(DateTime.parse(expiresAt).toLocal())}' : ''}',
              style: ETextStyles.bodySmMuted,
            ),
          ]),
        ),
        Switch(
          value: isActive,
          activeTrackColor: EColors.primary,
          onChanged: (v) =>
              controller.togglePromoCode(code['id'] as String, v),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: EColors.error, size: 18),
          onPressed: () => controller.deletePromoCode(code['id'] as String),
        ),
      ]),
    );
  }
}
