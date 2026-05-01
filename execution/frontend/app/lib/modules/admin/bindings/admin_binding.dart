import 'package:get/get.dart';
import '../controllers/master_controller.dart';
import '../controllers/staff_controller.dart';
import '../controllers/analytics_controller.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/calendar_token_repository.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminRepository>(() => AdminRepository());
    Get.lazyPut<CalendarTokenRepository>(() => SupabaseCalendarTokenRepository());
    Get.lazyPut<MasterController>(() => MasterController());
    Get.lazyPut<StaffController>(() => StaffController());
    Get.lazyPut<AnalyticsController>(() => AnalyticsController());
  }
}
