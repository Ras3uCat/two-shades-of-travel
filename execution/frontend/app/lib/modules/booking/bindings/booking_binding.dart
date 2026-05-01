import 'package:get/get.dart';
import '../controllers/booking_addons_controller.dart';
import '../controllers/booking_controller.dart';
import '../repositories/booking_repository.dart';
import '../repositories/supabase_booking_repository.dart';

class BookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingRepository>(
      () => SupabaseBookingRepository(),
    );
    Get.lazyPut<BookingAddonsController>(
      () => BookingAddonsController(),
    );
    Get.lazyPut<BookingController>(
      () => BookingController(),
    );
  }
}
