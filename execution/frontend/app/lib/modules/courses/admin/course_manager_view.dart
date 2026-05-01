import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../models/course_model.dart';
import '../repositories/course_repository.dart';

class CourseManagerView extends StatefulWidget {
  const CourseManagerView({super.key});

  @override
  State<CourseManagerView> createState() => _CourseManagerViewState();
}

class _CourseManagerViewState extends State<CourseManagerView> {
  final _repo = Get.find<CourseRepository>();
  bool _isLoading = true;
  List<CourseModel> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      _courses = await _repo.getAllCourses();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load courses');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCreateCourse() {
    // Basic dialog to create a course stub
    String title = '';
    String slug = '';

    Get.dialog(
      AlertDialog(
        title: const Text('Create New Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (v) => title = v,
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Slug (URL friendly)',
              ),
              onChanged: (v) => slug = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (title.isEmpty || slug.isEmpty) return;
              Get.back();
              setState(() => _isLoading = true);
              try {
                final newCourse = CourseModel(
                  id: '', // Supabase generated
                  slug: slug,
                  title: title,
                  priceCents: 0,
                  subscriptionPlanIds: [],
                  isPublished: false,
                  displayOrder: _courses.length,
                );
                await _repo.createCourse(newCourse);
                await _loadCourses();
              } catch (e) {
                Get.snackbar('Error', 'Failed to create course');
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _onEditCourse(CourseModel course) {
    // Navigate to section editor
    Get.toNamed(
      ERoutes.adminCourseEditor.replaceFirst(':id', course.id),
      arguments: course,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(ESpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Courses', style: ETextStyles.h2),
              ElevatedButton.icon(
                onPressed: _onCreateCourse,
                icon: const Icon(Icons.add),
                label: const Text('New Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESpacing.xl),
          Expanded(
            child: ListView.separated(
              itemCount: _courses.length,
              separatorBuilder: (_, _) => const SizedBox(height: ESpacing.md),
              itemBuilder: (_, i) {
                final course = _courses[i];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(course.title, style: ETextStyles.h4),
                    subtitle: Text(
                      'Slug: ${course.slug} • ${course.isPublished ? 'Published' : 'Draft'} • \$${course.price.toStringAsFixed(2)}',
                      style: ETextStyles.bodySmMuted,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Get.toNamed(
                            ERoutes.adminCourseEnrollments
                                .replaceFirst(':id', course.id),
                          ),
                          child: const Text('Enrollments'),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () => _onEditCourse(course),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
