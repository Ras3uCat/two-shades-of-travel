import 'package:get/get.dart';
import '../models/course_model.dart';
import '../models/enrollment_model.dart';
import '../repositories/course_repository.dart';

class CourseEnrollmentsController extends GetxController {
  CourseEnrollmentsController(this._repo);
  final CourseRepository _repo;

  final course = Rxn<CourseModel>();
  final enrollments = <CourseEnrollment>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    final courseId = Get.parameters['id'];
    if (courseId != null) {
      _loadData(courseId);
    } else {
      isLoading.value = false;
    }
  }

  Future<void> _loadData(String courseId) async {
    isLoading.value = true;
    try {
      // We might need to fetch the course title as well, but we don't have getCourseById.
      // So let's just get the list of courses to find this one.
      final courses = await _repo.getAllCourses();
      course.value = courses.firstWhereOrNull((c) => c.id == courseId);

      final eList = await _repo.getEnrollmentsForCourse(courseId);
      enrollments.assignAll(eList);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load enrollments');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStatus(String enrollmentId, String status) async {
    try {
      final updated = await _repo.updateEnrollmentStatus(enrollmentId, status);
      final index = enrollments.indexWhere((e) => e.id == enrollmentId);
      if (index >= 0) {
        enrollments[index] = updated;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status');
    }
  }
}
