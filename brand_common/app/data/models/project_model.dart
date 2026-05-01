class ProjectModel {
  final String title;
  final String description;
  final List<String> imagePaths;
  final List<String> technologies;
  final String? githubUrl;
  final String? liveUrl;

  ProjectModel({
    required this.title,
    required this.description,
    required this.imagePaths,
    required this.technologies,
    this.githubUrl,
    this.liveUrl,
  });

  String get primaryImage => imagePaths.isNotEmpty ? imagePaths.first : '';
  bool get hasMultipleImages => imagePaths.length > 1;
}
