import 'package:raspucat/utils/constants/exports.dart';

class TriangleWidget extends StatelessWidget {
  final int index;
  final BoxConstraints constraints;
  final double animationValue;

  const TriangleWidget({
    super.key,
    required this.index,
    required this.constraints,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    /// --- CONTROLLERS --- ///
    final triangleController = TriangleController.instance;
    final scrollController = EScrollController.instance;

    return Obx(() {
      final triangle = triangleController.triangles[index].value;

      final scrollOffset = scrollController.scrollOffset.value;

      // Calculate parallax offset based on triangle size
      // Larger triangles move slower (more background), smaller triangles move faster (more foreground)
      final parallaxFactor =
          (triangle.size - 40) / 120; // Normalize size to 0-1 range
      final parallaxOffsetY =
          scrollOffset *
          (0.3 + parallaxFactor * 0.4); // Range: 0.3x to 0.7x scroll speed
      final parallaxOffsetX =
          scrollOffset *
          (0.1 + parallaxFactor * 0.2); // Subtle horizontal movement

      // Calculate wrapped position for infinite scroll effect
      double wrappedY =
          (triangle.position.dy * constraints.maxHeight + parallaxOffsetY);
      double wrappedX =
          (triangle.position.dx * constraints.maxWidth + parallaxOffsetX);

      while (wrappedY < -triangle.size) {
        wrappedY += constraints.maxHeight + triangle.size;
      }
      while (wrappedY > constraints.maxHeight + triangle.size) {
        wrappedY -= constraints.maxHeight + triangle.size;
      }

      while (wrappedX < -triangle.size) {
        wrappedX += constraints.maxWidth + triangle.size;
      }
      while (wrappedX > constraints.maxWidth + triangle.size) {
        wrappedX -= constraints.maxWidth + triangle.size;
      }

      final pos = Offset(wrappedX, wrappedY);

      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: MouseRegion(
          onEnter: (_) => triangleController.onTriangleHover(index, true),
          onExit: (_) => triangleController.onTriangleHover(index, false),
          child: GestureDetector(
            onTap: () => triangleController.onTriangleTap(index),
            // Allow scroll events to pass through
            behavior: HitTestBehavior.translucent,
            // behavior: HitTestBehavior.deferToChild,
            child: Transform.rotate(
              angle: triangle.rotation + animationValue * 2 * pi,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: triangle.isHovered ? triangle.size * 1.2 : triangle.size,
                height: triangle.isHovered
                    ? triangle.size * 1.2
                    : triangle.size,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: triangle.isPopping ? 0.8 : 1.0,
                  child: CustomPaint(
                    painter: TrianglePainter(
                      triangle.color,
                      strokeWidth: triangle.isHovered ? 1.5 : 1.0,
                      isHovered: triangle.isHovered,
                      gradientDirection: triangle.gradientDirection,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
