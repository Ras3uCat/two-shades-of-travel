import 'package:raspucat/utils/constants/exports.dart';

/// --- REUSABLE NEON BUTTON WIDGET --- ///
class NeonButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color neonColor;
  final Color? hoverColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool enableOverlay;

  const NeonButton({
    super.key,
    required this.child,
    this.onTap,
    this.neonColor = EColors.primary,
    this.hoverColor = EColors.accent,
    this.borderRadius = ESizes.borderRadiusMd,
    this.padding = const EdgeInsets.all(ESizes.md),
    this.width,
    this.height,
    this.enableOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final isHovered = false.obs; // Local hover state per button

    return Obx(() {
      return SizedBox(
        width: width,
        height: height,

        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onHover: (value) {
            isHovered.value = value;
          },
          hoverColor: Colors.transparent,
          highlightColor: EColors.primary.withOpacity(0.1),
          splashColor: EColors.primary,
          onTap: onTap,
          child: AnimatedContainer(
            duration: EDurations.buttonHover,

            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                for (double i = 1; i < 3; i++)
                  BoxShadow(
                    color: isHovered.value
                        ? hoverColor!.withOpacity(1 - (i * 0.3))
                        : EColors.backgroundDark.withOpacity(1 - (i * 0.3)),
                    blurRadius: 3 * i,
                  ),
              ],

              color: EColors.backgroundDark.withOpacity(0.8),
              // color: isHovered.value
              //     ? hoverColor!.withOpacity(0.1)
              //     : EColors.backgroundDark,
              border: Border.all(
                color: isHovered.value
                    ? hoverColor?.withOpacity(0.7) ?? neonColor.withOpacity(0.8)
                    : neonColor.withOpacity(0.8),
                width: 2,
              ),
            ),
            child: isHovered.value && enableOverlay
                ? GradientOverlay(child: child)
                : child,
          ),
        ),
      );
    });
  }
}
