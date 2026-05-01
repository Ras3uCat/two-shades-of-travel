import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../core/widgets/seo_wrapper.dart';
import '../controllers/course_detail_controller.dart';
import '../models/course_model.dart';

class CourseDetailView extends GetView<CourseDetailController> {
  const CourseDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          backgroundColor: EColors.surface,
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final course = controller.course.value;
      if (course == null) {
        return Scaffold(
          appBar: AppBar(backgroundColor: EColors.surface, elevation: 0),
          backgroundColor: EColors.surface,
          body: const Center(child: Text('Course not found')),
        );
      }

      String? thumbUrl;
      if (course.thumbnailStoragePath != null &&
          course.thumbnailStoragePath!.isNotEmpty) {
        thumbUrl = Supabase.instance.client.storage
            .from('course-thumbnails')
            .getPublicUrl(course.thumbnailStoragePath!);
      }

      final isDesktop = MediaQuery.sizeOf(context).width > ESpacing.tabletBreak;

      final canonicalUrl = '${AppEnv.siteUrl}${ERoutes.courses}/${course.slug}';

      final jsonLd = jsonEncode({
        "@context": "https://schema.org",
        "@type": "Course",
        "name": course.title,
        "description": course.description ?? '',
        "provider": {
          "@type": "Organization",
          "name": AppEnv.clientName,
          "sameAs": AppEnv.siteUrl,
        },
      });

      return SeoWrapper(
        title: course.title,
        description: course.description,
        ogImage: thumbUrl,
        canonical: canonicalUrl,
        jsonLd: jsonLd,
        jsonLdId: 'course-${course.id}',
        child: Scaffold(
          backgroundColor: EColors.surface,
          appBar: AppBar(
            backgroundColor: EColors.surface,
            elevation: 0,
            leading: const BackButton(),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroSection(
                  course: course,
                  thumbUrl: thumbUrl,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: ESpacing.xxl),
                _MainContentGrid(controller: controller, isDesktop: isDesktop),
                const SizedBox(height: ESpacing.xxxl),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.course,
    required this.thumbUrl,
    required this.isDesktop,
  });

  final CourseModel course;
  final String? thumbUrl;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EColors.surfaceVariant,
      padding: EdgeInsets.symmetric(
        vertical: ESpacing.xxl,
        horizontal:
            isDesktop ? ESpacing.pagePaddingH * 2 : ESpacing.pagePaddingH,
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isDesktop ? 1 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: ETextStyles.h1),
                if (course.description != null) ...[
                  const SizedBox(height: ESpacing.md),
                  Text(
                    course.description!,
                    style: ETextStyles.bodyLg.copyWith(
                      color: EColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isDesktop)
            const SizedBox(width: ESpacing.xxl)
          else
            const SizedBox(height: ESpacing.xl),
          if (thumbUrl != null)
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: thumbUrl!,
                  width: double.infinity,
                  height: isDesktop ? 300 : 220,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MainContentGrid extends StatelessWidget {
  const _MainContentGrid({required this.controller, required this.isDesktop});

  final CourseDetailController controller;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal:
            isDesktop ? ESpacing.pagePaddingH * 2 : ESpacing.pagePaddingH,
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isDesktop ? 2 : 0,
            child: Container(
              padding: const EdgeInsets.all(ESpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(color: EColors.surfaceVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Course Syllabus', style: ETextStyles.h3),
                  if (controller.isEnrolled.value) ...[
                    const SizedBox(height: ESpacing.md),
                    LinearProgressIndicator(
                      value: controller.overallProgressPct.value,
                      backgroundColor: EColors.surfaceVariant,
                      color: EColors.primary,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: ESpacing.xs),
                    Text(
                      '${(controller.overallProgressPct.value * 100).toInt()}% Completed',
                      style: ETextStyles.bodySmMuted,
                    ),
                  ],
                  const SizedBox(height: ESpacing.xl),
                  if (controller.sections.isEmpty)
                    Text(
                      'No content available yet.',
                      style: ETextStyles.bodyMuted,
                    )
                  else
                    ...controller.sections.map(
                      (section) => _SectionItem(
                        section: section,
                        lessons: controller.lessons
                            .where((l) => l.sectionId == section.id)
                            .toList(),
                        controller: controller,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isDesktop)
            const SizedBox(width: ESpacing.xxl)
          else
            const SizedBox(height: ESpacing.xl),
          SizedBox(
            width: isDesktop ? 340 : double.infinity,
            child: _EnrollmentCard(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _SectionItem extends StatelessWidget {
  const _SectionItem({
    required this.section,
    required this.lessons,
    required this.controller,
  });

  final CourseSection section;
  final List<CourseLesson> lessons;
  final CourseDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: ESpacing.sm),
          child: Text(section.title, style: ETextStyles.h4),
        ),
        ...lessons.map((lesson) {
          final isCompleted = controller.completedLessonIds.contains(lesson.id);
          final isLocked =
              !lesson.isPreview && !controller.hasActiveAccess.value;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isCompleted
                  ? Icons.check_circle
                  : (isLocked ? Icons.lock_outline : Icons.play_circle_outline),
              color: isCompleted ? EColors.primary : EColors.onSurfaceMuted,
            ),
            title: Text(
              lesson.title,
              style: ETextStyles.bodyMd.copyWith(
                color: isLocked ? EColors.onSurfaceMuted : EColors.onSurface,
              ),
            ),
            trailing: lesson.durationSeconds != null
                ? Text(
                    '${lesson.durationSeconds! ~/ 60}:${(lesson.durationSeconds! % 60).toString().padLeft(2, '0')}',
                    style: ETextStyles.bodySmMuted,
                  )
                : null,
            onTap: () async {
              if (isLocked) {
                Get.snackbar(
                  'Locked',
                  'Please enroll or subscribe to access this lesson.',
                );
              } else {
                await Get.toNamed(
                  '${ERoutes.courses}/${controller.course.value!.slug}/lesson/${lesson.id}',
                );
                controller.reloadProgress();
              }
            },
          );
        }),
        const SizedBox(height: ESpacing.md),
      ],
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({required this.controller});
  final CourseDetailController controller;

  @override
  Widget build(BuildContext context) {
    final course = controller.course.value!;

    return Card(
      elevation: 0,
      color: EColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(ESpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.hasActiveAccess.value) ...[
              Text(
                'You have access',
                style: ETextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESpacing.md),
              ElevatedButton(
                onPressed: () {
                  if (controller.lessons.isNotEmpty) {
                    // Try to resume first incomplete lesson, otherwise start first lesson
                    final firstIncomplete = controller.lessons.firstWhere(
                      (l) => !controller.completedLessonIds.contains(l.id),
                      orElse: () => controller.lessons.first,
                    );
                    Get.toNamed(
                      '${ERoutes.courses}/${course.slug}/lesson/${firstIncomplete.id}',
                    )?.then((_) => controller.reloadProgress());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue Learning'),
              ),
            ] else ...[
              Text(
                course.priceCents > 0
                    ? '\$${course.price.toStringAsFixed(2)}'
                    : 'Free',
                style: ETextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESpacing.lg),
              ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.enroll(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enroll Now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
