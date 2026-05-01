import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/e_colors.dart';
import '../../core/theme/e_spacing.dart';
import '../../core/theme/e_text_styles.dart';
import 'menu_controller.dart';
import 'menu_item_model.dart';

class MenuSection extends GetView<MenuCatalogController> {
  const MenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.lg, vertical: ESpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Menu', style: ETextStyles.h2),
            const Spacer(),
            TextButton(
              onPressed: () => Get.toNamed(ERoutes.menu),
              child: Text('VIEW FULL MENU',
                  style: ETextStyles.labelSm.copyWith(color: EColors.primary)),
            ),
          ]),
          const SizedBox(height: ESpacing.md),
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final preview = controller.items
                .where((i) => i.isAvailable)
                .take(6)
                .toList();
            if (preview.isEmpty) return const SizedBox.shrink();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisExtent: 100,
                crossAxisSpacing: ESpacing.sm,
                mainAxisSpacing: ESpacing.sm,
              ),
              itemCount: preview.length,
              itemBuilder: (_, i) => _MenuCard(item: preview[i]),
            );
          }),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});
  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.name,
              style: ETextStyles.h4,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          Text(item.displayPrice,
              style: ETextStyles.bodySm.copyWith(color: EColors.primary)),
        ],
      ),
    );
  }
}
