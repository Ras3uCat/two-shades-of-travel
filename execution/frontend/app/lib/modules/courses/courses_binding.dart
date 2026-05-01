import 'package:get/get.dart';
import 'repositories/course_repository.dart';
import 'repositories/supabase_course_repository.dart';
import 'controllers/course_catalog_controller.dart';
import 'controllers/course_detail_controller.dart';
import 'controllers/lesson_player_controller.dart';
import 'admin/course_enrollments_controller.dart';

class CoursesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CourseRepository>(() => SupabaseCourseRepository());
    Get.lazyPut(() => CourseCatalogController(Get.find()), fenix: true);
    Get.lazyPut(() => CourseDetailController(Get.find()), fenix: true);
    Get.lazyPut(() => LessonPlayerController(Get.find()), fenix: true);
    Get.lazyPut(() => CourseEnrollmentsController(Get.find()), fenix: true);
  }
}
