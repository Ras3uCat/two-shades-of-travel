import 'package:get/get.dart';
import '../models/course_model.dart';
import '../repositories/course_repository.dart';

class CourseCatalogController extends GetxController {
  CourseCatalogController(this._repo);
  final CourseRepository _repo;

  final courses = <CourseModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    isLoading.value = true;
    try {
      courses.value = await _repo.getPublishedCourses();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load courses.');
    } finally {
      isLoading.value = false;
    }
  }
}
