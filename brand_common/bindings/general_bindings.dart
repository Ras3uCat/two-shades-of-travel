import 'package:raspucat/utils/constants/exports.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(TriangleController());
    // Get.put(EHoverController());
    Get.put(GradientController());
    Get.put(EScrollController());
    Get.put(SectionAnimationController());
    Get.put(ECarouselController(projects: EData.projects));
  }
}
