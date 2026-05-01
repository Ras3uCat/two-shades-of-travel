import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/e_colors.dart';
import '../../core/theme/e_spacing.dart';
import '../../core/theme/e_text_styles.dart';
import 'location_controller.dart';
import 'location_model.dart';

class LocationSelectorStep extends StatelessWidget {
  const LocationSelectorStep({super.key, required this.onSelected});

  final void Function(LocationModel location) onSelected;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<LocationController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a Location', style: ETextStyles.h2),
          const SizedBox(height: ESpacing.xs),
          Text(
            'Choose the location for your appointment.',
            style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
          ),
          const SizedBox(height: ESpacing.xl),
          Obx(() {
            if (ctrl.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (ctrl.error.value != null) {
              return Text(
                'Unable to load locations. Please try again.',
                style: ETextStyles.bodyMd.copyWith(color: EColors.error),
              );
            }
            final active = ctrl.locations
                .where((l) => l.isActive)
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            if (active.isEmpty) {
              return Text(
                'No locations available.',
                style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
              );
            }
            return Column(
              children: active
                  .map((loc) => _LocationCard(location: loc, onTap: () => onSelected(loc)))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location, required this.onTap});

  final LocationModel location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: ESpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(ESpacing.lg),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: EColors.primary),
              const SizedBox(width: ESpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.name, style: ETextStyles.h4),
                    if (location.displayAddress.isNotEmpty) ...[
                      const SizedBox(height: ESpacing.xs),
                      Text(
                        location.displayAddress,
                        style: ETextStyles.bodyMd
                            .copyWith(color: EColors.onSurfaceMuted),
                      ),
                    ],
                    if (location.phone != null &&
                        location.phone!.isNotEmpty) ...[
                      const SizedBox(height: ESpacing.xs),
                      Text(
                        location.phone!,
                        style: ETextStyles.bodyMd
                            .copyWith(color: EColors.onSurfaceMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_outlined,
                  color: EColors.onSurfaceMuted),
            ],
          ),
        ),
      ),
    );
  }
}
