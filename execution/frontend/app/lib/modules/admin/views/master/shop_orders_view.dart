import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../modules/shop/controllers/shop_admin_controller.dart';
import '../../../../modules/shop/models/shop_order_model.dart';
import '../admin_shell.dart';

class ShopOrdersView extends GetView<ShopAdminController> {
  const ShopOrdersView({super.key});

  static const _statuses = [
    'pending', 'paid', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded',
  ];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminShopOrders,
      isMaster: true,
      child: Column(children: [
        // Status filter
        Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(ESpacing.md),
              child: Row(children: [
                _FilterChip(
                  label: 'All',
                  selected: controller.statusFilter.value == null,
                  onTap: () => controller.statusFilter.value = null,
                ),
                ..._statuses.map((s) => _FilterChip(
                      label: _label(s),
                      selected: controller.statusFilter.value == s,
                      onTap: () => controller.statusFilter.value = s,
                    )),
              ]),
            )),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.orders.isEmpty) {
              return Center(
                child: Text('No orders',
                    style: ETextStyles.bodyMd
                        .copyWith(color: EColors.onSurfaceMuted)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: ESpacing.md),
              itemCount: controller.orders.length,
              itemBuilder: (_, i) =>
                  _OrderCard(order: controller.orders[i], controller: controller),
            );
          }),
        ),
      ]),
    );
  }

  static String _label(String s) =>
      s[0].toUpperCase() + s.substring(1);
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: ESpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: EColors.primaryLight,
        checkmarkColor: EColors.primary,
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order, required this.controller});
  final ShopOrderModel order;
  final ShopAdminController controller;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  static const _nextStatus = {
    'paid':       'processing',
    'processing': 'shipped',
    'shipped':    'delivered',
  };

  static const _statusColors = {
    'pending':   Colors.orange,
    'paid':      Colors.blue,
    'processing': Colors.purple,
    'shipped':   Colors.teal,
    'delivered': Colors.green,
    'cancelled': Colors.red,
    'refunded':  Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final order    = widget.order;
    final dateFmt  = DateFormat('MMM d, y');
    final color    = _statusColors[order.status] ?? Colors.grey;
    final next     = _nextStatus[order.status];

    return Card(
      margin: const EdgeInsets.only(bottom: ESpacing.sm),
      child: Column(children: [
        ListTile(
          title: Text(order.clientName, style: ETextStyles.bodyMd),
          subtitle: Text(
            '${order.clientEmail} · ${dateFmt.format(order.createdAt)}',
            style: ETextStyles.bodyMd.copyWith(
                color: EColors.onSurfaceMuted, fontSize: 12),
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Chip(
              label: Text(
                order.status[0].toUpperCase() + order.status.substring(1),
                style: TextStyle(color: color, fontSize: 12),
              ),
              backgroundColor: color.withValues(alpha: 0.1),
              side: BorderSide.none,
            ),
            const SizedBox(width: ESpacing.xs),
            Text(order.formattedTotal, style: ETextStyles.h3),
            IconButton(
              icon: Icon(_expanded
                  ? Icons.expand_less
                  : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ]),
        ),
        if (_expanded) ...[
          const Divider(height: 1),
          // Order items
          if (order.items != null)
            ...order.items!.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ESpacing.lg, vertical: ESpacing.xs),
                  child: Row(children: [
                    Expanded(
                        child: Text('${item.productName} × ${item.quantity}',
                            style: ETextStyles.bodyMd)),
                    Text(
                      '\$${(item.subtotalCents / 100).toStringAsFixed(2)}',
                      style: ETextStyles.bodyMd
                          .copyWith(color: EColors.onSurfaceMuted),
                    ),
                  ]),
                )),
          // Actions
          Padding(
            padding: const EdgeInsets.all(ESpacing.md),
            child: Row(children: [
              if (next != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: EColors.primary,
                      foregroundColor: Colors.white),
                  onPressed: () =>
                      widget.controller.updateOrderStatus(order.id, next),
                  child: Text('Mark as ${next[0].toUpperCase()}${next.substring(1)}'),
                ),
              const Spacer(),
              if (order.status != 'cancelled' && order.status != 'refunded')
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () =>
                      widget.controller.updateOrderStatus(order.id, 'cancelled'),
                  child: const Text('Cancel'),
                ),
            ]),
          ),
        ],
      ]),
    );
  }
}
