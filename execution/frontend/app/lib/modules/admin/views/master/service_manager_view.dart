import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../booking/models/service_model.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';

class ServiceManagerView extends GetView<MasterController> {
  const ServiceManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminServices,
      isMaster: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESpacing.lg),
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
            ),
            child: Row(children: [
              Text('Services', style: ETextStyles.h2),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text('NEW SERVICE', style: ETextStyles.button),
                onPressed: () => _showServiceForm(context),
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
              final grouped = controller.servicesByCategory;
              if (grouped.isEmpty) {
                return Center(
                    child: Text('No services yet.', style: ETextStyles.bodyMuted));
              }
              return ListView(
                padding: const EdgeInsets.all(ESpacing.lg),
                children: grouped.entries.map((entry) => _CategoryGroup(
                      category: entry.key,
                      services: entry.value,
                      onEdit: (svc) => _showServiceForm(context, svc),
                    )).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showServiceForm(BuildContext context, [ServiceModel? existing]) {
    final nameCtrl     = TextEditingController(text: existing?.name);
    final catCtrl      = TextEditingController(text: existing?.category);
    final descCtrl     = TextEditingController(text: existing?.description);
    final imageCtrl    = TextEditingController(text: existing?.imageUrl);
    final durationCtrl = TextEditingController(
        text: existing?.durationMinutes.toString());
    final priceCtrl    = TextEditingController(
        text: existing?.price.toStringAsFixed(0));

    Get.dialog(AlertDialog(
      backgroundColor: EColors.surface,
      title: Text(existing == null ? 'New Service' : 'Edit Service',
          style: ETextStyles.h3),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Field(controller: nameCtrl,  label: 'Name'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: catCtrl,   label: 'Category (e.g. Hair)'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: descCtrl,  label: 'Description'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: imageCtrl, label: 'Image URL (optional)'),
              const SizedBox(height: ESpacing.md),
              Row(children: [
                Expanded(child: _Field(
                    controller: durationCtrl,
                    label: 'Duration (min)',
                    type: TextInputType.number)),
                const SizedBox(width: ESpacing.md),
                Expanded(child: _Field(
                    controller: priceCtrl,
                    label: 'Price (\$)',
                    type: TextInputType.number)),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: Get.back,
            child: Text('CANCEL', style: ETextStyles.button.copyWith(
                color: EColors.onSurfaceMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: EColors.primary,
            foregroundColor: EColors.secondary,
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: () async {
            final img = imageCtrl.text.trim();
            final data = {
              'name':             nameCtrl.text.trim(),
              'category':         catCtrl.text.trim(),
              'description':      descCtrl.text.trim(),
              'image_url':        img.isEmpty ? null : img,
              'duration_minutes': int.tryParse(durationCtrl.text) ?? 60,
              'price':            double.tryParse(priceCtrl.text) ?? 0.0,
            };
            Get.back();
            if (existing == null) {
              await controller.createService(data);
            } else {
              await controller.updateService(existing.id, data);
            }
          },
          child: Text('SAVE', style: ETextStyles.button),
        ),
      ],
    ));
  }
}

class _CategoryGroup extends GetView<MasterController> {
  const _CategoryGroup({
    required this.category,
    required this.services,
    required this.onEdit,
  });
  final String category;
  final List<ServiceModel> services;
  final void Function(ServiceModel) onEdit;

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
            Expanded(child: Divider(
                color: EColors.divider, thickness: 0.5, height: 1)),
          ]),
        ),
        ...services.map((svc) => _ServiceTile(service: svc, onEdit: () => onEdit(svc))),
        const SizedBox(height: ESpacing.sm),
      ],
    );
  }
}

class _ServiceTile extends GetView<MasterController> {
  const _ServiceTile({required this.service, required this.onEdit});
  final ServiceModel service;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESpacing.sm),
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(
            color: service.isActive ? EColors.divider : EColors.error.withValues(alpha: 0.3),
            width: 0.5),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(service.name,
                style: ETextStyles.h4.copyWith(
                  color: service.isActive
                      ? EColors.onSurface
                      : EColors.onSurfaceMuted,
                )),
            Text(
              '${service.formattedDuration} · ${service.formattedPrice}',
              style: ETextStyles.bodySm.copyWith(color: EColors.primary),
            ),
          ]),
        ),
        Switch(
          value: service.isActive,
          activeTrackColor: EColors.primary,
          onChanged: (v) => controller.toggleService(service.id, v),
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
