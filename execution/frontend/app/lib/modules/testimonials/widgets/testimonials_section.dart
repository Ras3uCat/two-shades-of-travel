import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/testimonials_controller.dart';
import '../models/testimonial_model.dart';

/// Embeddable testimonials section — for use on home page or /testimonials.
/// Requires TestimonialsController to be registered.
class TestimonialsSection extends GetView<TestimonialsController> {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < ESpacing.mobileBreak;

    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.testimonials.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: ESpacing.sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ESpacing.pagePaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WHAT CLIENTS SAY',
                      style: ETextStyles.overline.copyWith(
                          color: EColors.primary)),
                  const SizedBox(height: ESpacing.sm),
                  Text('Reviews', style: ETextStyles.h2),
                ],
              ),
            ),
            const SizedBox(height: ESpacing.xl),
            if (isMobile)
              _VerticalList(items: controller.testimonials)
            else
              _HorizontalGrid(items: controller.testimonials),
          ],
        ),
      );
    });
  }
}

class _VerticalList extends StatelessWidget {
  const _VerticalList({required this.items});
  final List<TestimonialModel> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESpacing.pagePaddingH),
      child: Column(
        children: items
            .map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: ESpacing.md),
                  child: _TestimonialCard(item: t),
                ))
            .toList(),
      ),
    );
  }
}

class _HorizontalGrid extends StatelessWidget {
  const _HorizontalGrid({required this.items});
  final List<TestimonialModel> items;

  @override
  Widget build(BuildContext context) {
    // Clamp to 3 per row; overflow scrolls horizontally
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ESpacing.pagePaddingH),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: ESpacing.md),
        itemBuilder: (_, i) => SizedBox(
          width: 300,
          child: _TestimonialCard(item: items[i]),
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.item});
  final TestimonialModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESpacing.lg),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.rating != null)
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < item.rating! ? Icons.star : Icons.star_border,
                  color: EColors.primary,
                  size: 16,
                ),
              ),
            ),
          const SizedBox(height: ESpacing.sm),
          Expanded(
            child: Text(
              '"${item.quote}"',
              style: ETextStyles.body,
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: ESpacing.md),
          Text(
            item.author,
            style: ETextStyles.label,
          ),
          if (item.role != null)
            Text(item.role!, style: ETextStyles.bodySmMuted),
        ],
      ),
    );
  }
}
