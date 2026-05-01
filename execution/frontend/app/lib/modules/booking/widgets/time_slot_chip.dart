import 'package:flutter/material.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_text_styles.dart';
import '../models/time_slot_model.dart';

class TimeSlotChip extends StatefulWidget {
  const TimeSlotChip({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlotModel slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<TimeSlotChip> createState() => _TimeSlotChipState();
}

class _TimeSlotChipState extends State<TimeSlotChip> {
  bool _hovered = false;

  bool get _isBooked    => widget.slot.isBooked;
  bool get _isSelected  => widget.isSelected;
  bool get _isAvailable => !_isBooked;

  Color get _bgColor {
    if (_isSelected) return EColors.primary.withValues(alpha: 0.1);
    if (_isBooked)   return EColors.divider;
    if (_hovered)    return EColors.surfaceVariant;
    return EColors.surface;
  }

  Color get _borderColor {
    if (_isSelected) return EColors.primary;
    if (_isBooked)   return EColors.divider;
    if (_hovered)    return EColors.onSurfaceMuted.withValues(alpha: 0.4);
    return EColors.divider;
  }

  Color get _timeColor {
    if (_isSelected) return EColors.primary;
    if (_isBooked)   return EColors.onSurfaceMuted.withValues(alpha: 0.35);
    return EColors.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isBooked
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) { if (_isAvailable) setState(() => _hovered = true); },
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _isBooked ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64.0,
          decoration: BoxDecoration(
            color: _bgColor,
            border: Border.all(
              color: _borderColor,
              width: _isSelected ? 1.0 : 0.5,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.slot.formattedTime,
                      style: ETextStyles.h4.copyWith(
                        color: _timeColor,
                        fontSize: 16,
                        decoration: _isBooked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor:
                            EColors.onSurfaceMuted.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isBooked
                          ? (widget.slot.isDirectBooked
                              ? 'TAKEN'
                              : 'UNAVAILABLE')
                          : '→ ${widget.slot.formattedEndTime}',
                      style: ETextStyles.duration.copyWith(
                        color: _isBooked
                            ? EColors.error.withValues(alpha: 0.6)
                            : EColors.onSurfaceMuted,
                        fontSize: 10,
                        letterSpacing: _isBooked ? 1.5 : 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isBooked)
                Positioned.fill(
                  child: CustomPaint(painter: _DiagonalLinePainter()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EColors.divider.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_DiagonalLinePainter old) => false;
}
