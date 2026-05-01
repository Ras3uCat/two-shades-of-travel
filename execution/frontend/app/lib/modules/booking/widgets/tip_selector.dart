import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/booking_addons_controller.dart';

class TipSelector extends StatefulWidget {
  const TipSelector({super.key, required this.addons, required this.totalPrice});
  final BookingAddonsController addons;
  final double totalPrice;

  @override
  State<TipSelector> createState() => _TipSelectorState();
}

class _TipSelectorState extends State<TipSelector> {
  final _customController = TextEditingController();
  bool _showCustom = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _selectPct(double pct) {
    setState(() => _showCustom = false);
    _customController.clear();
    final cents = (widget.totalPrice * pct * 100).round();
    widget.addons.setTip(cents);
  }

  void _selectNone() {
    setState(() => _showCustom = false);
    _customController.clear();
    widget.addons.setTip(0);
  }

  void _selectCustom() {
    setState(() => _showCustom = true);
    widget.addons.setTip(0);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tipCents = widget.addons.tipAmountCents.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ADD GRATUITY', style: ETextStyles.label),
          const SizedBox(height: ESpacing.sm),
          Wrap(
            spacing: ESpacing.sm,
            children: [
              _TipChip(
                label: 'None',
                selected: tipCents == 0 && !_showCustom,
                onTap: _selectNone,
              ),
              _TipChip(
                label: '10%',
                selected: !_showCustom &&
                    tipCents == (widget.totalPrice * 0.10 * 100).round(),
                onTap: () => _selectPct(0.10),
              ),
              _TipChip(
                label: '15%',
                selected: !_showCustom &&
                    tipCents == (widget.totalPrice * 0.15 * 100).round(),
                onTap: () => _selectPct(0.15),
              ),
              _TipChip(
                label: '20%',
                selected: !_showCustom &&
                    tipCents == (widget.totalPrice * 0.20 * 100).round(),
                onTap: () => _selectPct(0.20),
              ),
              _TipChip(
                label: 'Custom',
                selected: _showCustom,
                onTap: _selectCustom,
              ),
            ],
          ),
          if (_showCustom) ...[
            const SizedBox(height: ESpacing.sm),
            TextFormField(
              controller: _customController,
              style: ETextStyles.inputText,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'CUSTOM TIP AMOUNT (\$)',
                labelStyle: ETextStyles.inputLabel,
                prefixText: '\$ ',
              ),
              onChanged: (v) {
                final dollars = double.tryParse(v) ?? 0;
                widget.addons.setTip((dollars * 100).round());
              },
            ),
          ],
        ],
      );
    });
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: ESpacing.md, vertical: ESpacing.xs),
        decoration: BoxDecoration(
          color: selected ? EColors.primary : Colors.transparent,
          border: Border.all(
            color: selected ? EColors.primary : EColors.divider,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: ETextStyles.labelSm.copyWith(
            color: selected ? EColors.secondary : EColors.onSurface,
          ),
        ),
      ),
    );
  }
}
