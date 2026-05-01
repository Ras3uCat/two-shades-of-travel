import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import 'course_enrollments_controller.dart';

class CourseEnrollmentsView extends GetView<CourseEnrollmentsController> {
  const CourseEnrollmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.course.value != null
                ? 'Enrollments: ${controller.course.value!.title}'
                : 'Enrollments',
          ),
        ),
        backgroundColor: EColors.surface,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.enrollments.isEmpty) {
          return const Center(
            child: Text('No enrollments found for this course.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(ESpacing.md),
          itemCount: controller.enrollments.length,
          itemBuilder: (context, index) {
            final e = controller.enrollments[index];
            final DateFormat formatter = DateFormat('MMM d, yyyy h:mm a');

            return Card(
              margin: const EdgeInsets.only(bottom: ESpacing.md),
              color: EColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(ESpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.clientEmail, style: ETextStyles.h4),
                    const SizedBox(height: ESpacing.xs),
                    Row(
                      children: [
                        _StatusBadge(status: e.status),
                        const SizedBox(width: ESpacing.sm),
                        Text(
                          e.enrolledAt != null
                              ? 'Enrolled: ${formatter.format(e.enrolledAt!)}'
                              : 'Pending Enrollment',
                          style: ETextStyles.bodySmMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: ESpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (e.status != 'active')
                          ElevatedButton(
                            onPressed: () =>
                                controller.updateStatus(e.id, 'active'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Activate'),
                          ),
                        if (e.status != 'active')
                          const SizedBox(width: ESpacing.sm),
                        if (e.status != 'cancelled')
                          OutlinedButton(
                            onPressed: () =>
                                controller.updateStatus(e.id, 'cancelled'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text('Cancel'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'active':
        bgColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green[800]!;
        break;
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange[800]!;
        break;
      case 'cancelled':
        bgColor = EColors.error.withValues(alpha: 0.2);
        textColor = EColors.error;
        break;
      default:
        bgColor = EColors.surface;
        textColor = EColors.onSurfaceMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: ETextStyles.bodySmMuted.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
