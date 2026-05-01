import 'package:raspucat/utils/constants/exports.dart';

class AnimatedOnView extends StatelessWidget {
  final String id;
  final Widget child;
  final Offset startOffset;
  final Duration duration;
  final SectionAnimationController controller;

  const AnimatedOnView({
    super.key,
    required this.id,
    required this.child,
    required this.controller,
    this.startOffset = const Offset(0, 50),
    this.duration = EDurations.animationOnView,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = controller.get(id);

    return VisibilityDetector(
      key: key ?? UniqueKey(),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1) {
          // Entering viewport → play animation
          controller.show(id);
        } else {
          // Leaving viewport → reset animation
          isVisible.value = false;
        }
      },
      child: Obx(() {
        final progress = isVisible.value ? 1.0 : 0.0;
        return AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            startOffset.dx * (1 - progress),
            startOffset.dy * (1 - progress),
            0,
          ),
          child: AnimatedOpacity(
            opacity: progress,
            duration: duration,
            child: child,
          ),
        );
      }),
    );
  }
}
