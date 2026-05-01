import 'package:flutter/material.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../models/service_model.dart';

class ServiceCard extends StatefulWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _liftController;
  late final Animation<double> _liftAnim;

  @override
  void initState() {
    super.initState();
    _liftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _liftAnim = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _liftController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(ServiceCard old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _liftController.forward().then((_) => _liftController.reverse());
    }
  }

  @override
  void dispose() {
    _liftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _liftAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _liftAnim.value),
        child: child,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 100.0,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? EColors.primary.withValues(alpha: 0.06)
                  : _hovered
                      ? EColors.surfaceVariant
                      : EColors.surface,
              border: Border.all(
                color: widget.isSelected
                    ? EColors.primary
                    : _hovered
                        ? EColors.onSurfaceMuted.withValues(alpha: 0.4)
                        : EColors.divider,
                width: widget.isSelected ? 1.0 : 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(ESpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: ESpacing.sm, vertical: 3),
                        color: widget.isSelected
                            ? EColors.primary
                            : EColors.divider,
                        child: Text(
                          widget.service.categoryLabel,
                          style: ETextStyles.labelSm.copyWith(
                            fontSize: 9,
                            color: widget.isSelected
                                ? EColors.secondary
                                : EColors.onSurfaceMuted,
                          ),
                        ),
                      ),
                      if (widget.isSelected)
                        Icon(Icons.check, color: EColors.primary, size: 16),
                    ],
                  ),
                  const Spacer(),
                  Text(widget.service.name, style: ETextStyles.h4),
                  const SizedBox(height: ESpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.service.formattedDuration,
                          style: ETextStyles.duration),
                      Text(widget.service.formattedPrice,
                          style: ETextStyles.price),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
