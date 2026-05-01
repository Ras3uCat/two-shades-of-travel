import '../models/course_model.dart';
import '../models/enrollment_model.dart';

abstract class CourseRepository {
  Future<List<CourseModel>> getPublishedCourses();
  Future<CourseModel?> getCourseBySlug(String slug);
  Future<List<CourseSection>> getSections(String courseId);
  Future<List<CourseLesson>> getLessons(String courseId);

  // Auth required methods
  Future<CourseEnrollment?> getEnrollment(String courseId);
  Future<List<LessonProgress>> getProgress(String courseId);
  Future<String?> getLessonVideoUrl(String lessonId);
  Future<void> saveLessonProgress(
    String lessonId,
    int watchedSeconds,
    bool completed,
  );
  Future<String?> createCourseCheckout(
    String courseId,
    String successUrl,
    String cancelUrl,
  );

  // Admin methods
  Future<List<CourseModel>> getAllCourses();
  Future<CourseModel> createCourse(CourseModel course);
  Future<CourseModel> updateCourse(CourseModel course);
  Future<void> deleteCourse(String id);

  Future<CourseSection> createSection(CourseSection section);
  Future<CourseSection> updateSection(CourseSection section);
  Future<void> deleteSection(String id);

  Future<CourseLesson> createLesson(CourseLesson lesson);
  Future<CourseLesson> updateLesson(CourseLesson lesson);
  Future<void> deleteLesson(String id);

  // Admin Enrollments
  Future<List<CourseEnrollment>> getEnrollmentsForCourse(String courseId);
  Future<CourseEnrollment> updateEnrollmentStatus(
    String enrollmentId,
    String status,
  );
}
