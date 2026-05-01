import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/e_colors.dart';
import '../../core/theme/e_spacing.dart';
import '../../core/theme/e_text_styles.dart';
import '../admin/views/admin_shell.dart';
import 'menu_controller.dart';
import 'menu_item_model.dart';

class MenuManagerView extends GetView<MenuCatalogController> {
  const MenuManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminMenu,
      isMaster: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESpacing.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
            ),
            child: Row(children: [
              Text('Menu', style: ETextStyles.h2),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text('NEW ITEM', style: ETextStyles.button),
                onPressed: () => _showItemForm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: EColors.secondary,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.items.isEmpty) {
                return Center(
                    child: Text('No items yet.', style: ETextStyles.bodyMuted));
              }
              final grouped = <String, List<MenuItemModel>>{};
              for (final item in controller.items) {
                (grouped[item.category] ??= []).add(item);
              }
              return ListView(
                padding: const EdgeInsets.all(ESpacing.lg),
                children: grouped.entries
                    .map((e) => _MenuCategoryGroup(
                          category: e.key,
                          items: e.value,
                          onEdit: (item) => _showItemForm(context, item),
                        ))
                    .toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showItemForm(BuildContext context, [MenuItemModel? existing]) {
    final nameCtrl  = TextEditingController(text: existing?.name);
    final catCtrl   = TextEditingController(text: existing?.category);
    final descCtrl  = TextEditingController(text: existing?.description);
    final imageCtrl = TextEditingController(text: existing?.imageUrl);
    final priceCtrl = TextEditingController(
        text: existing?.price != null
            ? (existing!.price! / 100).toStringAsFixed(2)
            : '');
    final orderCtrl =
        TextEditingController(text: (existing?.sortOrder ?? 0).toString());

    Get.dialog(AlertDialog(
      backgroundColor: EColors.surface,
      title: Text(existing == null ? 'New Item' : 'Edit Item', style: ETextStyles.h3),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Field(controller: nameCtrl, label: 'Name'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: catCtrl, label: 'Category (e.g. Starters)'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: descCtrl, label: 'Description (optional)'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: imageCtrl, label: 'Image URL (optional)'),
              const SizedBox(height: ESpacing.md),
              Row(children: [
                Expanded(child: _Field(
                    controller: priceCtrl,
                    label: r'Price $ (blank = on request)',
                    type: TextInputType.number)),
                const SizedBox(width: ESpacing.md),
                Expanded(child: _Field(
                    controller: orderCtrl,
                    label: 'Sort order',
                    type: TextInputType.number)),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        if (existing != null)
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.deleteItem(existing.id);
            },
            child: Text('DELETE',
                style: ETextStyles.button.copyWith(color: EColors.error)),
          ),
        TextButton(
            onPressed: Get.back,
            child: Text('CANCEL',
                style: ETextStyles.button.copyWith(color: EColors.onSurfaceMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: EColors.primary,
            foregroundColor: EColors.secondary,
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: () async {
            final priceInput = double.tryParse(priceCtrl.text.trim());
            final img = imageCtrl.text.trim();
            final data = {
              'name':        nameCtrl.text.trim(),
              'category':    catCtrl.text.trim().isEmpty ? 'General' : catCtrl.text.trim(),
              'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              'image_url':   img.isEmpty ? null : img,
              'price':       priceInput == null ? null : (priceInput * 100).round(),
              'sort_order':  int.tryParse(orderCtrl.text) ?? 0,
            };
            Get.back();
            if (existing == null) {
              await controller.createItem(data);
            } else {
              await controller.updateItem(existing.id, data);
            }
          },
          child: Text('SAVE', style: ETextStyles.button),
        ),
      ],
    ));
  }
}

class _MenuCategoryGroup extends StatelessWidget {
  const _MenuCategoryGroup({
    required this.category,
    required this.items,
    required this.onEdit,
  });
  final String category;
  final List<MenuItemModel> items;
  final void Function(MenuItemModel) onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: ESpacing.sm, top: ESpacing.lg),
          child: Row(children: [
            Text(category.toUpperCase(), style: ETextStyles.overline),
            const SizedBox(width: ESpacing.md),
            Expanded(child: Divider(color: EColors.divider, thickness: 0.5, height: 1)),
          ]),
        ),
        ...items.map((item) => _MenuItemAdminTile(
              item: item,
              onEdit: () => onEdit(item),
            )),
      ],
    );
  }
}

class _MenuItemAdminTile extends StatelessWidget {
  const _MenuItemAdminTile({required this.item, required this.onEdit});
  final MenuItemModel item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESpacing.sm),
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(
            color: item.isAvailable
                ? EColors.divider
                : EColors.error.withValues(alpha: 0.3),
            width: 0.5),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name,
                style: ETextStyles.h4.copyWith(
                  color: item.isAvailable ? EColors.onSurface : EColors.onSurfaceMuted,
                )),
            Text(item.displayPrice,
                style: ETextStyles.bodySm.copyWith(color: EColors.primary)),
          ]),
        ),
        IconButton(
          icon: Icon(Icons.edit_outlined, color: EColors.onSurfaceMuted, size: 18),
          onPressed: onEdit,
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.type = TextInputType.text,
  });
  final TextEditingController controller;
  final String label;
  final TextInputType type;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: ETextStyles.inputText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ETextStyles.inputLabel,
      ),
    );
  }
}
