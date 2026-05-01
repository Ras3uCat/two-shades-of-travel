import 'package:get/get.dart';
import 'location_controller.dart';
import 'location_repository.dart';
import 'supabase_location_repository.dart';

class LocationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationRepository>(() => SupabaseLocationRepository());
    Get.lazyPut<LocationController>(() => LocationController());
  }
}
