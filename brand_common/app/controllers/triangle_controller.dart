import 'package:raspucat/utils/constants/exports.dart';

class TriangleController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static TriangleController get instance => Get.find();
  late final AnimationController animationController;
  final Random _random = Random();
  final int triangleCount = 20;
  late final List<Rx<TriangleModel>> triangles;

  @override
  void onInit() {
    super.onInit();
    triangles = List.generate(
      triangleCount,
      (index) => TriangleModel(
        position: Offset(_random.nextDouble(), _random.nextDouble()),
        size: 40 + _random.nextDouble() * 120, // Increased size range: 40-160px
        rotation: _random.nextDouble() * 2 * pi,
        color: EColors.colors[_random.nextInt(EColors.colors.length)],
        originalColor: EColors.colors[_random.nextInt(EColors.colors.length)],
        gradientDirection: _random.nextInt(4), // Random direction 0-3
      ).obs,
    );
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  void onTriangleTap(int index) {
    // Pop effect - make triangle slightly more visible briefly and add subtle bounce
    triangles[index].update((triangle) {
      if (triangle != null) {
        // Store the current color before modifying it
        final currentColor = triangle.color;
        triangle.color = currentColor.withOpacity(0.6);
        triangle.isPopping = true;
        // Add a small bounce effect by temporarily increasing size
        triangle.size = triangle.size * 1.1;
      }
    });

    // After pop effect, respawn in random spot
    Future.delayed(const Duration(milliseconds: 200), () {
      triangles[index].update((triangle) {
        if (triangle != null) {
          // Generate new random position
          triangle.position = Offset(
            _random.nextDouble(),
            _random.nextDouble(),
          );
          // Generate new random size
          triangle.size =
              40 + _random.nextDouble() * 120; // Same size range: 40-160px
          // Generate new random rotation
          triangle.rotation = _random.nextDouble() * 2 * pi;
          // Generate new random color with proper opacity
          final newColor =
              EColors.colors[_random.nextInt(EColors.colors.length)];
          triangle.color = newColor;
          triangle.originalColor = newColor;
          triangle.gradientDirection = _random.nextInt(
            4,
          ); // New random direction
          triangle.isPopping = false;
        }
      });
    });
  }

  void onTriangleHover(int index, bool hovering) {
    triangles[index].update((triangle) {
      if (triangle != null) {
        triangle.isHovered = hovering;
        if (hovering) {
          // Make triangle more visible on hover by increasing opacity
          final hsl = HSLColor.fromColor(triangle.originalColor);
          triangle.color = hsl
              .withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0))
              .toColor();
        } else {
          // Return to original color
          triangle.color = triangle.originalColor;
        }
      }
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
