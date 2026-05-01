import 'package:get/get.dart';
import '../controllers/events_admin_controller.dart';
import '../repositories/events_repository.dart';
import '../repositories/supabase_events_repository.dart';

class EventsAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventsRepository>(() => SupabaseEventsRepository());
    Get.lazyPut<EventsAdminController>(() => EventsAdminController(Get.find()));
  }
}
