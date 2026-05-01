import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../controllers/course_catalog_controller.dart';
import 'courses_section.dart'; // To reuse CourseCard

class CourseCatalogView extends GetView<CourseCatalogController> {
  const CourseCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > ESpacing.tabletBreak;

    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        title: Text('Courses', style: ETextStyles.h2),
        backgroundColor: EColors.surface,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.courses.isEmpty) {
          return Center(
            child: Text(
              'No courses available right now.',
              style: ETextStyles.bodyLg.copyWith(color: EColors.onSurfaceMuted),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(ESpacing.pagePaddingH),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop
                  ? 3
                  : (MediaQuery.sizeOf(context).width > ESpacing.mobileBreak
                        ? 2
                        : 1),
              crossAxisSpacing: ESpacing.lg,
              mainAxisSpacing: ESpacing.lg,
              childAspectRatio: 0.85,
            ),
            itemCount: controller.courses.length,
            itemBuilder: (_, i) => CourseCard(course: controller.courses[i]),
          ),
        );
      }),
    );
  }
}
