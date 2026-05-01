import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart';

class ServiceDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut<HomeController>(() => HomeController());
    }
  }
}
