import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';
import 'booking_tile.dart';

class BookingOverviewView extends GetView<MasterController> {
  const BookingOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.admin,
      isMaster: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onRefresh: controller.loadAll),
          const _StatsBar(),
          _Filters(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.bookings.isEmpty) {
                return Center(
                  child: Text('No bookings found.',
                      style: ETextStyles.bodyMuted),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(ESpacing.lg),
                itemCount: controller.bookings.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: ESpacing.sm),
                itemBuilder: (_, i) =>
                    BookingTile(booking: controller.bookings[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESpacing.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Text('Bookings', style: ETextStyles.h2),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: EColors.onSurfaceMuted),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.controller});
  final MasterController controller;

  static const _statuses = [null, 'pending', 'confirmed', 'cancelled', 'completed'];
  static const _labels   = ['All', 'Pending', 'Confirmed', 'Cancelled', 'Completed'];

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
            itemCount: _statuses.length,
            separatorBuilder: (_, _) => const SizedBox(width: ESpacing.sm),
            itemBuilder: (_, i) {
              final isActive = controller.statusFilter.value == _statuses[i];
              return GestureDetector(
                onTap: () =>
                    controller.applyFilters(status: _statuses[i]),
                child: Chip(
                  label: Text(_labels[i],
                      style: ETextStyles.labelSm.copyWith(
                        color: isActive
                            ? EColors.secondary
                            : EColors.onSurface,
                      )),
                  backgroundColor:
                      isActive ? EColors.primary : EColors.surface,
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

class _StatsBar extends GetView<MasterController> {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final all       = controller.bookings;
      final confirmed = all.where((b) => b.status == 'confirmed').toList();
      final pending   = all.where((b) => b.status == 'pending').length;
      final revenue   = confirmed.fold(0.0, (s, b) => s + b.totalPrice);

      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: ESpacing.lg, vertical: ESpacing.sm),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: EColors.divider, width: 0.5)),
        ),
        child: Row(children: [
          _Stat(label: 'Shown',     value: '${all.length}'),
          _StatDiv(),
          _Stat(label: 'Confirmed', value: '${confirmed.length}'),
          _StatDiv(),
          _Stat(label: 'Revenue',   value: '\$${revenue.toStringAsFixed(0)}'),
          _StatDiv(),
          _Stat(label: 'Pending',   value: '$pending'),
        ]),
      );
    });
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: ETextStyles.h4),
          Text(label,
              style: ETextStyles.labelSm
                  .copyWith(color: EColors.onSurfaceMuted)),
        ],
      );
}

class _StatDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ESpacing.lg),
        child: Container(width: 0.5, height: 32, color: EColors.divider),
      );
}
