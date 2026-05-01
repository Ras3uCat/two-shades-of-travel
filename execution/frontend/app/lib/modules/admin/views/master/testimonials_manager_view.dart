import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../testimonials/models/testimonial_model.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';

class TestimonialsManagerView extends GetView<MasterController> {
  const TestimonialsManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminTestimonials,
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
              Text('Testimonials', style: ETextStyles.h2),
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
              final items = controller.testimonials;
              if (items.isEmpty) {
                return Center(
                    child: Text('No testimonials yet.',
                        style: ETextStyles.bodyMuted));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(ESpacing.lg),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: ESpacing.sm),
                itemBuilder: (_, i) => _TestimonialTile(
                  item: items[i],
                  onEdit: () => _showForm(context, items[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, [TestimonialModel? existing]) {
    final authorCtrl = TextEditingController(text: existing?.author);
    final roleCtrl   = TextEditingController(text: existing?.role);
    final quoteCtrl  = TextEditingController(text: existing?.quote);
    int rating       = existing?.rating ?? 5;
    int order        = existing?.displayOrder ?? controller.testimonials.length;

    Get.dialog(StatefulBuilder(
      builder: (_, setState) => AlertDialog(
        backgroundColor: EColors.surface,
        title: Text(existing == null ? 'Add Testimonial' : 'Edit Testimonial',
            style: ETextStyles.h3),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Field(controller: authorCtrl, label: 'Author name'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: roleCtrl, label: 'Role / title (optional)'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: quoteCtrl, label: 'Quote', maxLines: 3),
              const SizedBox(height: ESpacing.md),
              Row(children: [
                Text('Rating', style: ETextStyles.label),
                const SizedBox(width: ESpacing.md),
                ...List.generate(5, (i) => GestureDetector(
                      onTap: () => setState(() => rating = i + 1),
                      child: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: EColors.primary,
                        size: 24,
                      ),
                    )),
                const Spacer(),
                SizedBox(
                  width: 60,
                  child: _Field(
                    controller:
                        TextEditingController(text: order.toString()),
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
                style:
                    ETextStyles.button.copyWith(color: EColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.secondary,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: () async {
              if (authorCtrl.text.trim().isEmpty ||
                  quoteCtrl.text.trim().isEmpty) { return; }
              final data = {
                'author':        authorCtrl.text.trim(),
                'role':          roleCtrl.text.trim().isEmpty
                    ? null
                    : roleCtrl.text.trim(),
                'quote':         quoteCtrl.text.trim(),
                'rating':        rating,
                'display_order': order,
              };
              Get.back();
              if (existing == null) {
                await controller.createTestimonial(data);
              } else {
                await controller.updateTestimonial(existing.id, data);
              }
            },
            child: Text('SAVE', style: ETextStyles.button),
          ),
        ],
      ),
    ));
  }
}

class _TestimonialTile extends GetView<MasterController> {
  const _TestimonialTile({required this.item, required this.onEdit});
  final TestimonialModel item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (item.rating != null)
              Row(children: List.generate(
                  5,
                  (i) => Icon(
                        i < item.rating! ? Icons.star : Icons.star_border,
                        color: EColors.primary,
                        size: 14,
                      ))),
            const SizedBox(height: ESpacing.xs),
            Text('"${item.quote}"',
                style: ETextStyles.body, maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: ESpacing.xs),
            Text(
              item.role != null
                  ? '${item.author} · ${item.role}'
                  : item.author,
              style: ETextStyles.bodySmMuted,
            ),
          ]),
        ),
        Column(children: [
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: EColors.onSurfaceMuted, size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: EColors.error, size: 18),
            onPressed: () => controller.deleteTestimonial(item.id),
          ),
        ]),
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
