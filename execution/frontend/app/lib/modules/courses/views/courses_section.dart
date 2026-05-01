import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../controllers/course_catalog_controller.dart';
import '../models/course_model.dart';

class CoursesSection extends StatelessWidget {
  const CoursesSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CourseCatalogController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<CourseCatalogController>();

    return Obx(() {
      if (controller.courses.isEmpty) return const SizedBox.shrink();

      final featured = controller.courses.take(3).toList();
      final isDesktop = MediaQuery.sizeOf(context).width > ESpacing.tabletBreak;

      return Container(
        padding: const EdgeInsets.symmetric(
          vertical: ESpacing.xxxl,
          horizontal: ESpacing.pagePaddingH,
        ),
        color: EColors.surface,
        child: Column(
          children: [
            Text(
              'Featured Courses',
              style: ETextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ESpacing.sm),
            Text(
              'Expand your knowledge',
              style: ETextStyles.bodyLg.copyWith(color: EColors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ESpacing.xxl),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 1,
                crossAxisSpacing: ESpacing.lg,
                mainAxisSpacing: ESpacing.lg,
                childAspectRatio: 0.85,
              ),
              itemCount: featured.length,
              itemBuilder: (_, i) => CourseCard(course: featured[i]),
            ),
            const SizedBox(height: ESpacing.xl),
            OutlinedButton(
              onPressed: () => Get.toNamed(ERoutes.courses),
              child: const Text('View All Courses'),
            ),
          ],
        ),
      );
    });
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    String? thumbUrl;
    if (course.thumbnailStoragePath != null &&
        course.thumbnailStoragePath!.isNotEmpty) {
      thumbUrl = Supabase.instance.client.storage
          .from('course-thumbnails')
          .getPublicUrl(course.thumbnailStoragePath!);
    }

    return GestureDetector(
      onTap: () => Get.toNamed('${ERoutes.courses}/${course.slug}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: thumbUrl != null
                  ? CachedNetworkImage(
                      imageUrl: thumbUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(ESpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: ETextStyles.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (course.description != null) ...[
                      const SizedBox(height: ESpacing.xs),
                      Text(
                        course.description!,
                        style: ETextStyles.bodySmMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      course.priceCents > 0
                          ? '\$${course.price.toStringAsFixed(2)}'
                          : 'Free',
                      style: ETextStyles.bodyMd.copyWith(
                        color: EColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: EColors.primaryLight,
        child: Center(
          child:
              Icon(Icons.play_circle_outline, size: 48, color: EColors.primary),
        ),
      );
}
