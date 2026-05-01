import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../faq/models/faq_item_model.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';

class FaqManagerView extends GetView<MasterController> {
  const FaqManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminFaq,
      isMaster: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: EColors.divider, width: 0.5)),
            ),
            child: Row(children: [
              Text('FAQ', style: ETextStyles.h2),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text('ADD', style: ETextStyles.button),
                onPressed: () => _showForm(context),
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
              final items = controller.faqs;
              if (items.isEmpty) {
                return Center(
                    child: Text('No FAQs yet.', style: ETextStyles.bodyMuted));
              }

              // Group by category
              final grouped = <String, List<FaqItemModel>>{};
              for (final item in items) {
                (grouped[item.category ?? ''] ??= []).add(item);
              }

              return ListView(
                padding: const EdgeInsets.all(ESpacing.lg),
                children: grouped.entries.map((entry) {
                  return _FaqGroup(
                    category: entry.key,
                    items: entry.value,
                    onEdit: (item) => _showForm(context, item),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, [FaqItemModel? existing]) {
    final questionCtrl = TextEditingController(text: existing?.question);
    final answerCtrl   = TextEditingController(text: existing?.answer);
    final categoryCtrl = TextEditingController(text: existing?.category);
    int order = existing?.displayOrder ?? controller.faqs.length;

    Get.dialog(AlertDialog(
      backgroundColor: EColors.surface,
      title: Text(
          existing == null ? 'Add FAQ' : 'Edit FAQ', style: ETextStyles.h3),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(controller: questionCtrl, label: 'Question'),
            const SizedBox(height: ESpacing.md),
            _Field(
                controller: answerCtrl, label: 'Answer', maxLines: 4),
            const SizedBox(height: ESpacing.md),
            Row(children: [
              Expanded(
                child: _Field(
                    controller: categoryCtrl,
                    label: 'Category (optional)'),
              ),
              const SizedBox(width: ESpacing.md),
              SizedBox(
                width: 72,
                child: _Field(
                  controller: TextEditingController(text: order.toString()),
                  label: 'Order',
                  type: TextInputType.number,
                  onChanged: (v) => order = int.tryParse(v) ?? order,
                ),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text('CANCEL',
              style: ETextStyles.button.copyWith(
                  color: EColors.onSurfaceMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: EColors.primary,
            foregroundColor: EColors.secondary,
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: () async {
            if (questionCtrl.text.trim().isEmpty ||
                answerCtrl.text.trim().isEmpty) { return; }
            final data = {
              'question':     questionCtrl.text.trim(),
              'answer':       answerCtrl.text.trim(),
              'category':     categoryCtrl.text.trim().isEmpty
                  ? null
                  : categoryCtrl.text.trim(),
              'display_order': order,
            };
            Get.back();
            if (existing == null) {
              await controller.createFaq(data);
            } else {
              await controller.updateFaq(existing.id, data);
            }
          },
          child: Text('SAVE', style: ETextStyles.button),
        ),
      ],
    ));
  }
}

class _FaqGroup extends GetView<MasterController> {
  const _FaqGroup({
    required this.category,
    required this.items,
    required this.onEdit,
  });
  final String category;
  final List<FaqItemModel> items;
  final void Function(FaqItemModel) onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category.isNotEmpty)
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
        ...items.map((item) => _FaqTile(
              item: item,
              onEdit: () => onEdit(item),
            )),
        const SizedBox(height: ESpacing.sm),
      ],
    );
  }
}

class _FaqTile extends GetView<MasterController> {
  const _FaqTile({required this.item, required this.onEdit});
  final FaqItemModel item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESpacing.sm),
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.question, style: ETextStyles.h4),
                const SizedBox(height: ESpacing.xs),
                Text(item.answer,
                    style: ETextStyles.bodySmMuted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ]),
        ),
        IconButton(
          icon: Icon(Icons.edit_outlined,
              color: EColors.onSurfaceMuted, size: 18),
          onPressed: onEdit,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: EColors.error, size: 18),
          onPressed: () => controller.deleteFaq(item.id),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.type = TextInputType.text,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType type;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: ETextStyles.inputText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ETextStyles.inputLabel,
      ),
    );
  }
}
