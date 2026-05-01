import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/e_colors.dart';
import '../../core/theme/e_spacing.dart';
import '../../core/theme/e_text_styles.dart';
import 'menu_controller.dart';
import 'menu_item_model.dart';

class MenuCatalogView extends GetView<MenuCatalogController> {
  const MenuCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        elevation: 0,
        title: Text('Menu', style: ETextStyles.h3),
        iconTheme: IconThemeData(color: EColors.onSurface),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.items.isEmpty) {
          return Center(
              child: Text('No items yet.', style: ETextStyles.bodyMuted));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CategoryFilter(controller: controller),
            Expanded(
              child: Obx(() => ListView(
                    padding: const EdgeInsets.all(ESpacing.lg),
                    children: _buildGrouped(controller.filteredItems),
                  )),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildGrouped(List<MenuItemModel> items) {
    final grouped = <String, List<MenuItemModel>>{};
    for (final item in items) {
      (grouped[item.category] ??= []).add(item);
    }
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(_CategoryHeader(category: entry.key));
      for (final item in entry.value) {
        widgets.add(_MenuItemTile(item: item));
      }
    }
    return widgets;
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.controller});
  final MenuCatalogController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: ESpacing.lg),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
      ),
      child: Obx(() => ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: ESpacing.sm),
            itemBuilder: (_, i) {
              final cat = controller.categories[i];
              final isActive = controller.selectedCategory.value == cat;
              return GestureDetector(
                onTap: () => controller.selectedCategory.value = cat,
                child: Chip(
                  label: Text(cat,
                      style: ETextStyles.labelSm.copyWith(
                        color: isActive ? EColors.secondary : EColors.onSurface,
                      )),
                  backgroundColor: isActive ? EColors.primary : EColors.surface,
                  side: BorderSide(
                      color: isActive ? EColors.primary : EColors.divider,
                      width: 0.5),
                  padding: EdgeInsets.zero,
                ),
              );
            },
          )),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ESpacing.lg, bottom: ESpacing.sm),
      child: Row(children: [
        Text(category.toUpperCase(), style: ETextStyles.overline),
        const SizedBox(width: ESpacing.md),
        Expanded(child: Divider(color: EColors.divider, thickness: 0.5, height: 1)),
      ]),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({required this.item});
  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isAvailable ? 1.0 : 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: ESpacing.sm),
        padding: const EdgeInsets.all(ESpacing.md),
        decoration: BoxDecoration(
          color: EColors.surfaceVariant,
          border: Border.all(color: EColors.divider, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.imageUrl!,
                  width: 64, height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(width: 64, height: 64),
                ),
              ),
              const SizedBox(width: ESpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(item.name, style: ETextStyles.h4)),
                    Text(item.displayPrice,
                        style: ETextStyles.bodySm.copyWith(color: EColors.primary)),
                  ]),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(item.description!,
                        style: ETextStyles.bodySm.copyWith(color: EColors.onSurfaceMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (!item.isAvailable) ...[
                    const SizedBox(height: 4),
                    Text('Unavailable',
                        style: ETextStyles.labelSm.copyWith(color: EColors.onSurfaceMuted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
