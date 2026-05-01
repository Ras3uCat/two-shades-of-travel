import 'package:raspucat/utils/constants/exports.dart';

class GradientOverlay extends StatelessWidget {
  final Widget child;

  const GradientOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final gradientController = GradientController.instance;

    return Obx(() {
      final double offset = gradientController.offset.value;

      return ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: [
              EColors.primary,
              // EColors.accent,
              ?Color.lerp(EColors.primary, EColors.white, 0.4),
              EColors.primary,
              ?Color.lerp(EColors.accent, EColors.black, 0.4),
              // ?Color.lerp(EColors.primary, EColors.black, 0.4),
              EColors.primary,
            ],
            begin: Alignment(-2 + offset, -2 + offset),
            end: Alignment(2 + offset, 2 + offset),
            stops: const [0.0, 0.2, 0.4, 0.6, 1.0],
            tileMode: TileMode.repeated,
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcIn,
        child: child,
      );
    });
  }
}
