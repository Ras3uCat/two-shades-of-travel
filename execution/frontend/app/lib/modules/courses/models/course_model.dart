class CourseModel {
  const CourseModel({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.thumbnailStoragePath,
    required this.priceCents,
    this.stripePriceId,
    required this.subscriptionPlanIds,
    this.instructorId,
    required this.isPublished,
    required this.displayOrder,
    this.createdAt,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? thumbnailStoragePath;
  final int priceCents;
  final String? stripePriceId;
  final List<String> subscriptionPlanIds;
  final String? instructorId;
  final bool isPublished;
  final int displayOrder;
  final DateTime? createdAt;

  double get price => priceCents / 100;

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
    id: json['id'] as String,
    slug: json['slug'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    thumbnailStoragePath: json['thumbnail_storage_path'] as String?,
    priceCents: json['price_cents'] as int? ?? 0,
    stripePriceId: json['stripe_price_id'] as String?,
    subscriptionPlanIds: (json['subscription_plan_ids'] as List? ?? [])
        .cast<String>(),
    instructorId: json['instructor_id'] as String?,
    isPublished: json['is_published'] as bool? ?? false,
    displayOrder: json['display_order'] as int? ?? 0,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'description': description,
    'thumbnail_storage_path': thumbnailStoragePath,
    'price_cents': priceCents,
    'stripe_price_id': stripePriceId,
    'subscription_plan_ids': subscriptionPlanIds,
    'instructor_id': instructorId,
    'is_published': isPublished,
    'display_order': displayOrder,
  };
}

class CourseSection {
  const CourseSection({
    required this.id,
    required this.courseId,
    required this.title,
    required this.displayOrder,
  });

  final String id;
  final String courseId;
  final String title;
  final int displayOrder;

  factory CourseSection.fromJson(Map<String, dynamic> json) => CourseSection(
    id: json['id'] as String,
    courseId: json['course_id'] as String,
    title: json['title'] as String,
    displayOrder: json['display_order'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'course_id': courseId,
    'title': title,
    'display_order': displayOrder,
  };
}

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.courseId,
    required this.sectionId,
    required this.title,
    this.description,
    this.videoStoragePath,
    this.durationSeconds,
    required this.isPreview,
    required this.displayOrder,
  });

  final String id;
  final String courseId;
  final String sectionId;
  final String title;
  final String? description;
  final String? videoStoragePath;
  final int? durationSeconds;
  final bool isPreview;
  final int displayOrder;

  factory CourseLesson.fromJson(Map<String, dynamic> json) => CourseLesson(
    id: json['id'] as String,
    courseId: json['course_id'] as String,
    sectionId: json['section_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    videoStoragePath: json['video_storage_path'] as String?,
    durationSeconds: json['duration_seconds'] as int?,
    isPreview: json['is_preview'] as bool? ?? false,
    displayOrder: json['display_order'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'course_id': courseId,
    'section_id': sectionId,
    'title': title,
    'description': description,
    'video_storage_path': videoStoragePath,
    'duration_seconds': durationSeconds,
    'is_preview': isPreview,
    'display_order': displayOrder,
  };
}
