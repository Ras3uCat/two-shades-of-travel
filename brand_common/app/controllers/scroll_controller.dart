import 'package:raspucat/utils/constants/exports.dart';

class EScrollController extends GetxController {
  static EScrollController get instance => Get.find();
  final scrollController = ScrollController();

  final scrollOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
  }

  void scrollTo(double offset) {
    scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll); // Remove listener
    scrollController.dispose();
    super.onClose();
  }
}
