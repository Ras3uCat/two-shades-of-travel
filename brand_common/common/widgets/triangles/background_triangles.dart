import 'package:raspucat/utils/constants/exports.dart';

class BackgroundTriangles extends StatelessWidget {
  const BackgroundTriangles({super.key});

  @override
  Widget build(BuildContext context) {
    /// --- CONTROLLERS --- ///

    final triangleController = TriangleController.instance;

    return AnimatedBuilder(
      animation: triangleController.animationController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: List.generate(triangleController.triangles.length, (
                index,
              ) {
                return TriangleWidget(
                  index: index,
                  constraints: constraints,
                  animationValue: triangleController.animationController.value,
                );
              }),
            );
          },
        );
      },
    );
  }
}
