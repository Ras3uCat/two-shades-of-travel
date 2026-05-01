import 'package:get/get.dart';
import '../../booking/repositories/booking_repository.dart';
import '../../booking/repositories/supabase_booking_repository.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BookingRepository>()) {
      Get.lazyPut<BookingRepository>(() => SupabaseBookingRepository());
    }
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
