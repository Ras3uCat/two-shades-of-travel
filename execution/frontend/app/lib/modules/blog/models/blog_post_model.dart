class BlogPostModel {
  final String    id;
  final String    slug;
  final String    title;
  final String    body;
  final String?   coverUrl;
  final bool      isPublished;
  final DateTime? publishedAt;
  final DateTime  createdAt;

  const BlogPostModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    this.coverUrl,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
  });

  factory BlogPostModel.fromMap(Map<String, dynamic> map) {
    return BlogPostModel(
      id:          map['id']           as String,
      slug:        map['slug']         as String,
      title:       map['title']        as String,
      body:        map['body']         as String,
      coverUrl:    map['cover_url']    as String?,
      isPublished: map['is_published'] as bool? ?? false,
      publishedAt: map['published_at'] != null
          ? DateTime.parse(map['published_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Used for INSERT only — id, created_at, updated_at are DB-generated.
  Map<String, dynamic> toInsertMap() => {
        'slug':         slug,
        'title':        title,
        'body':         body,
        'cover_url':    coverUrl,
        'is_published': isPublished,
        'published_at': isPublished
            ? DateTime.now().toUtc().toIso8601String()
            : null,
      };
}
