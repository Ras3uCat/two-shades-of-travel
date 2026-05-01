import 'package:raspucat/utils/constants/exports.dart';

class ECarouselController extends GetxController {
  static ECarouselController get instance => Get.find();

  final CarouselSliderController carouselController =
      CarouselSliderController();
  final currentPage = 0.obs;
  final List<ProjectModel> projects;
  // final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  ECarouselController({required this.projects});
  final RxInt hoveredIndex = (-1).obs;

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void jumpTo(int index) {
    carouselController.animateToPage(index);
  }

  void setHoveredIndex(int index) {
    hoveredIndex.value = index;
  }

  void clearHover() {
    hoveredIndex.value = -1;
  }

  @override
  void onClose() {
    hoveredIndex.close();
    currentPage.close();
    super.onClose();
  }
}
