import 'package:get/get.dart';
import '../controllers/events_controller.dart';
import '../repositories/events_repository.dart';
import '../repositories/supabase_events_repository.dart';

class EventsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventsRepository>(() => SupabaseEventsRepository());
    Get.lazyPut<EventsController>(() => EventsController(Get.find()));
  }
}
