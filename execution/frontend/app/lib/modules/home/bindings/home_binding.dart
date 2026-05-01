import 'package:get/get.dart';
import '../../../core/config/app_env.dart';
import '../../testimonials/controllers/testimonials_controller.dart';
import '../../courses/controllers/course_catalog_controller.dart';
import '../../courses/repositories/course_repository.dart';
import '../../courses/repositories/supabase_course_repository.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());

    // Register TestimonialsController so the embeddable testimonials
    // section works when 'testimonials' is in the HOME_SECTIONS list.
    if (AppEnv.moduleEnabled('testimonials')) {
      Get.lazyPut<TestimonialsController>(() => TestimonialsController());
    }

    // Register CourseCatalogController so CoursesSection renders on the home
    // page. Without this, the controller is only available after navigating
    // to /courses, making the featured section permanently empty.
    if (AppEnv.moduleEnabled('courses')) {
      Get.lazyPut<CourseRepository>(() => SupabaseCourseRepository());
      Get.lazyPut<CourseCatalogController>(
        () => CourseCatalogController(Get.find()),
        fenix: true,
      );
    }
  }
}
