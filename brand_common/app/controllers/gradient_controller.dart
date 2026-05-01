import 'package:raspucat/utils/constants/exports.dart';
import 'dart:async';

class GradientController extends GetxController {
  static GradientController get instance => Get.find();

  var offset = 0.0.obs;
  Timer? _animationTimer;

  @override
  void onInit() {
    super.onInit();
    animateGradient();
  }

  void animateGradient() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      offset.value += 0.01;
    });
  }

  @override
  void onClose() {
    _animationTimer?.cancel(); // Cancel the timer
    super.onClose();
  }
}
