import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/course_model.dart';
import '../models/enrollment_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../repositories/course_repository.dart';

class CourseDetailController extends GetxController {
  CourseDetailController(this._repo);
  final CourseRepository _repo;

  final course = Rxn<CourseModel>();
  final sections = <CourseSection>[].obs;
  final lessons = <CourseLesson>[].obs;
  final enrollment = Rxn<CourseEnrollment>();
  final progress = <LessonProgress>[].obs;

  final isLoading = true.obs;
  final isEnrolled = false.obs;
  final hasActiveAccess = false.obs;
  final overallProgressPct = 0.0.obs;
  final completedLessonIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final slug = Get.parameters['slug'];
    if (slug != null) {
      _loadData(slug);
    } else {
      isLoading.value = false;
    }
  }

  Future<void> _loadData(String slug) async {
    isLoading.value = true;
    try {
      final c = await _repo.getCourseBySlug(slug);
      if (c == null) return;

      course.value = c;

      // Load sections and lessons concurrently
      final parts = await Future.wait([
        _repo.getSections(c.id),
        _repo.getLessons(c.id),
      ]);

      sections.value = parts[0] as List<CourseSection>;
      lessons.value = parts[1] as List<CourseLesson>;

      // Load enrollment and progress if authenticated
      final auth = Get.find<AuthController>();
      if (auth.isSignedIn) {
        final authParts = await Future.wait([
          _repo.getEnrollment(c.id),
          _repo.getProgress(c.id),
        ]);

        final e = authParts[0] as CourseEnrollment?;
        final pList = authParts[1] as List<LessonProgress>;

        enrollment.value = e;
        progress.value = pList;

        isEnrolled.value = e != null;

        // Note: For subscriptions we don't have direct access check here yet.
        hasActiveAccess.value = (e != null && e.isActive);

        _calculateProgress();
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to load course details.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reloadProgress() async {
    final c = course.value;
    final auth = Get.find<AuthController>();
    if (c != null && auth.isSignedIn) {
      try {
        final pList = await _repo.getProgress(c.id);
        progress.value = pList;
        _calculateProgress();
      } catch (_) {
        // Silently fail on reload
      }
    }
  }

  Future<void> enroll() async {
    final c = course.value;
    if (c == null) return;

    isLoading.value = true;
    try {
      final successUrl = '${AppEnv.siteUrl}${ERoutes.courses}/${c.slug}';
      final cancelUrl = '${AppEnv.siteUrl}${ERoutes.courses}/${c.slug}';

      final checkoutUrl = await _repo.createCourseCheckout(
        c.id,
        successUrl,
        cancelUrl,
      );

      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar('Error', 'Could not open checkout page.');
        }
      } else {
        Get.snackbar('Error', 'Failed to initialize checkout.');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during enrollment.');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateProgress() {
    if (lessons.isEmpty) {
      overallProgressPct.value = 0;
      return;
    }

    int completedCount = 0;
    completedLessonIds.clear();

    for (final p in progress) {
      if (p.isCompleted) {
        completedCount++;
        completedLessonIds.add(p.lessonId);
      }
    }

    overallProgressPct.value = completedCount / lessons.length;
  }
}
