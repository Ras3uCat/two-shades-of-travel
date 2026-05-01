import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_model.dart';
import '../models/enrollment_model.dart';
import 'course_repository.dart';

class SupabaseCourseRepository implements CourseRepository {
  final _client = Supabase.instance.client;

  // ── Public courses ─────────────────────────────────────────────────────────────

  @override
  Future<List<CourseModel>> getPublishedCourses() async {
    final rows = await _client
        .from('courses')
        .select()
        .eq('is_published', true)
        .order('display_order');
    return rows.map((r) => CourseModel.fromJson(r)).toList();
  }

  @override
  Future<CourseModel?> getCourseBySlug(String slug) async {
    final data = await _client
        .from('courses')
        .select()
        .eq('slug', slug)
        .maybeSingle();
    if (data == null) return null;
    return CourseModel.fromJson(data);
  }

  @override
  Future<List<CourseSection>> getSections(String courseId) async {
    final rows = await _client
        .from('course_sections')
        .select()
        .eq('course_id', courseId)
        .order('display_order');
    return rows.map((r) => CourseSection.fromJson(r)).toList();
  }

  @override
  Future<List<CourseLesson>> getLessons(String courseId) async {
    final rows = await _client
        .from('course_lessons')
        .select()
        .eq('course_id', courseId)
        .order('display_order');
    return rows.map((r) => CourseLesson.fromJson(r)).toList();
  }

  // ── Auth required methods ────────────────────────────────────────────────────

  @override
  Future<CourseEnrollment?> getEnrollment(String courseId) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return null;

    final data = await _client
        .from('course_enrollments')
        .select()
        .eq('course_id', courseId)
        .eq('client_email', email)
        .maybeSingle();

    if (data == null) return null;
    return CourseEnrollment.fromJson(data);
  }

  @override
  Future<List<LessonProgress>> getProgress(String courseId) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return [];

    final rows = await _client
        .from('lesson_progress')
        .select('*, course_lessons!inner(course_id)')
        .eq('client_email', email)
        .eq('course_lessons.course_id', courseId);

    return rows.map((r) => LessonProgress.fromJson(r)).toList();
  }

  @override
  Future<String?> getLessonVideoUrl(String lessonId) async {
    try {
      final res = await _client.functions.invoke(
        'get-lesson-video',
        body: {'lesson_id': lessonId},
      );
      return res.data['signed_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveLessonProgress(
    String lessonId,
    int watchedSeconds,
    bool completed,
  ) async {
    try {
      await _client.functions.invoke(
        'save-lesson-progress',
        body: {
          'lesson_id': lessonId,
          'watched_seconds': watchedSeconds,
          'completed': completed,
        },
      );
    } catch (_) {}
  }

  @override
  Future<String?> createCourseCheckout(
    String courseId,
    String successUrl,
    String cancelUrl,
  ) async {
    try {
      final res = await _client.functions.invoke(
        'create-course-checkout',
        body: {
          'course_id': courseId,
          'success_url': successUrl,
          'cancel_url': cancelUrl,
        },
      );
      return res.data['url'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ── Admin methods ────────────────────────────────────────────────────────────

  @override
  Future<List<CourseModel>> getAllCourses() async {
    final rows = await _client.from('courses').select().order('display_order');
    return rows.map((r) => CourseModel.fromJson(r)).toList();
  }

  @override
  Future<CourseModel> createCourse(CourseModel course) async {
    final data = await _client
        .from('courses')
        .insert(course.toJson())
        .select()
        .single();
    return CourseModel.fromJson(data);
  }

  @override
  Future<CourseModel> updateCourse(CourseModel course) async {
    final data = await _client
        .from('courses')
        .update(course.toJson())
        .eq('id', course.id)
        .select()
        .single();
    return CourseModel.fromJson(data);
  }

  @override
  Future<void> deleteCourse(String id) async {
    await _client.from('courses').delete().eq('id', id);
  }

  @override
  Future<CourseSection> createSection(CourseSection section) async {
    final data = await _client
        .from('course_sections')
        .insert(section.toJson())
        .select()
        .single();
    return CourseSection.fromJson(data);
  }

  @override
  Future<CourseSection> updateSection(CourseSection section) async {
    final data = await _client
        .from('course_sections')
        .update(section.toJson())
        .eq('id', section.id)
        .select()
        .single();
    return CourseSection.fromJson(data);
  }

  @override
  Future<void> deleteSection(String id) async {
    await _client.from('course_sections').delete().eq('id', id);
  }

  @override
  Future<CourseLesson> createLesson(CourseLesson lesson) async {
    final data = await _client
        .from('course_lessons')
        .insert(lesson.toJson())
        .select()
        .single();
    return CourseLesson.fromJson(data);
  }

  @override
  Future<CourseLesson> updateLesson(CourseLesson lesson) async {
    final data = await _client
        .from('course_lessons')
        .update(lesson.toJson())
        .eq('id', lesson.id)
        .select()
        .single();
    return CourseLesson.fromJson(data);
  }

  @override
  Future<void> deleteLesson(String id) async {
    await _client.from('course_lessons').delete().eq('id', id);
  }

  @override
  Future<List<CourseEnrollment>> getEnrollmentsForCourse(
    String courseId,
  ) async {
    final rows = await _client
        .from('course_enrollments')
        .select()
        .eq('course_id', courseId)
        .order('enrolled_at', ascending: false);
    return rows.map((r) => CourseEnrollment.fromJson(r)).toList();
  }

  @override
  Future<CourseEnrollment> updateEnrollmentStatus(
    String enrollmentId,
    String status,
  ) async {
    final data = await _client
        .from('course_enrollments')
        .update({
          'status': status,
          if (status == 'active')
            'enrolled_at': DateTime.now().toIso8601String(),
        })
        .eq('id', enrollmentId)
        .select()
        .single();
    return CourseEnrollment.fromJson(data);
  }
}
