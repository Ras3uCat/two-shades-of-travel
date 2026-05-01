import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';

/// InitialBinding — registers shared services and controllers
/// that must be available before any route renders.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
  }
}
