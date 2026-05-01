class CourseEnrollment {
  const CourseEnrollment({
    required this.id,
    required this.courseId,
    required this.clientEmail,
    required this.status,
    this.enrolledAt,
    this.stripeCheckoutSession,
    this.expiresAt,
  });

  final String id;
  final String courseId;
  final String clientEmail;
  final String status; // 'pending' | 'active' | 'cancelled'
  final DateTime? enrolledAt;
  final String? stripeCheckoutSession;
  final DateTime? expiresAt;

  bool get isActive =>
      status == 'active' &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) =>
      CourseEnrollment(
        id: json['id'] as String,
        courseId: json['course_id'] as String,
        clientEmail: json['client_email'] as String,
        status: json['status'] as String? ?? 'pending',
        enrolledAt: json['enrolled_at'] != null
            ? DateTime.parse(json['enrolled_at'] as String)
            : null,
        stripeCheckoutSession: json['stripe_checkout_session'] as String?,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'course_id': courseId,
    'client_email': clientEmail,
    'status': status,
    'enrolled_at': enrolledAt?.toIso8601String(),
    'stripe_checkout_session': stripeCheckoutSession,
    'expires_at': expiresAt?.toIso8601String(),
  };
}

class LessonProgress {
  const LessonProgress({
    required this.id,
    required this.lessonId,
    required this.clientEmail,
    required this.watchedSeconds,
    this.completedAt,
    this.updatedAt,
  });

  final String id;
  final String lessonId;
  final String clientEmail;
  final int watchedSeconds;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  bool get isCompleted => completedAt != null;

  factory LessonProgress.fromJson(Map<String, dynamic> json) => LessonProgress(
    id: json['id'] as String,
    lessonId: json['lesson_id'] as String,
    clientEmail: json['client_email'] as String,
    watchedSeconds: json['watched_seconds'] as int? ?? 0,
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'lesson_id': lessonId,
    'client_email': clientEmail,
    'watched_seconds': watchedSeconds,
    'completed_at': completedAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
