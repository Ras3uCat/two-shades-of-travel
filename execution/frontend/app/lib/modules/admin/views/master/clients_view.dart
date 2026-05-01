import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';

class ClientsView extends GetView<MasterController> {
  const ClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminClients,
      isMaster: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onRefresh: controller.loadClients),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.clients.isEmpty) {
                return Center(
                  child: Text('No clients yet.', style: ETextStyles.bodyMuted),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(ESpacing.lg),
                itemCount: controller.clients.length,
                separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
                itemBuilder: (_, i) => _ClientTile(client: controller.clients[i]),
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
          Text('Clients', style: ETextStyles.h2),
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

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client});
  final Map<String, dynamic> client;

  @override
  Widget build(BuildContext context) {
    final name      = client['client_name']   as String? ?? '—';
    final email     = client['client_email']  as String? ?? '—';
    final count     = (client['booking_count'] as num?)?.toInt() ?? 0;
    final spent     = (client['total_spent']   as num?)?.toDouble() ?? 0.0;
    final rawDate   = client['last_visit']     as String?;
    final lastVisit = rawDate != null
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(rawDate).toLocal())
        : '—';

    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,  style: ETextStyles.h4),
                Text(email, style: ETextStyles.bodySm
                    .copyWith(color: EColors.onSurfaceMuted)),
              ],
            ),
          ),
          const SizedBox(width: ESpacing.md),
          _Stat(label: 'Visits', value: '$count'),
          const SizedBox(width: ESpacing.lg),
          _Stat(label: 'Spent',  value: '\$${spent.toStringAsFixed(0)}'),
          const SizedBox(width: ESpacing.lg),
          _Stat(label: 'Last',   value: lastVisit),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value, style: ETextStyles.h4),
          Text(label, style: ETextStyles.labelSm
              .copyWith(color: EColors.onSurfaceMuted)),
        ],
      );
}
