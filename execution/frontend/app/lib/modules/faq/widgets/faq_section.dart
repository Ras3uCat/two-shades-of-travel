import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/faq_controller.dart';
import '../models/faq_item_model.dart';

/// Embeddable FAQ accordion — for use on home page or /faq.
/// Requires FaqController to be registered.
class FaqSection extends GetView<FaqController> {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.faqs.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: ESpacing.sectionGap),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ESpacing.pagePaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FREQUENTLY ASKED',
                      style: ETextStyles.overline.copyWith(
                          color: EColors.primary)),
                  const SizedBox(height: ESpacing.sm),
                  Text('Questions', style: ETextStyles.h2),
                  const SizedBox(height: ESpacing.xl),
                  ...controller.categories.map((cat) =>
                      _CategoryAccordion(
                        category: cat,
                        items: controller.itemsForCategory(cat),
                      )),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _CategoryAccordion extends StatelessWidget {
  const _CategoryAccordion({required this.category, required this.items});
  final String category;
  final List<FaqItemModel> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
                top: ESpacing.lg, bottom: ESpacing.sm),
            child: Row(children: [
              Text(category.toUpperCase(), style: ETextStyles.overline),
              const SizedBox(width: ESpacing.md),
              Expanded(
                  child: Divider(
                      color: EColors.divider, thickness: 0.5, height: 1)),
            ]),
          ),
        ],
        ...items.map((item) => _FaqTile(item: item)),
        const SizedBox(height: ESpacing.sm),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});
  final FaqItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: EColors.divider, width: 0.5)),
      ),
      child: Theme(
        // Remove the default expansion tile dividers
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
              vertical: ESpacing.sm),
          childrenPadding: const EdgeInsets.only(
              bottom: ESpacing.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: EColors.primary,
          collapsedIconColor: EColors.onSurfaceMuted,
          title: Text(item.question, style: ETextStyles.h4),
          children: [
            Text(item.answer,
                style: ETextStyles.body.copyWith(
                    color: EColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}
