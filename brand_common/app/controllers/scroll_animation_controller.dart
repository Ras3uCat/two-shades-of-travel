import 'package:raspucat/utils/constants/exports.dart';

class SectionAnimationController extends GetxController {
  static SectionAnimationController get instance => Get.find();
  // Map element IDs to visibility state
  final Map<String, RxBool> elements = {};

  void register(String id) {
    elements.putIfAbsent(id, () => false.obs);
  }

  RxBool get(String id) {
    register(id);
    return elements[id]!;
  }

  void show(String id) {
    get(id).value = true;
  }

  @override
  void onClose() {
    elements.clear();
    super.onClose();
  }
}
