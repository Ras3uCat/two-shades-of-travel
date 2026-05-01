import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/analytics_controller.dart';
import '../admin_shell.dart';
import 'analytics_charts.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminAnalytics,
      isMaster: true,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(ESpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(controller: controller),
              const SizedBox(height: ESpacing.lg),
              _KpiRow(kpis: controller.kpis),
              const SizedBox(height: ESpacing.xl),
              Text('Revenue', style: ETextStyles.h3),
              const SizedBox(height: ESpacing.sm),
              Obx(() => RevenueBarChart(data: controller.revenueByPeriod)),
              const SizedBox(height: ESpacing.xl),
              _BottomRow(controller: controller),
              if (AppEnv.moduleEnabled('shop')) ...[
                const SizedBox(height: ESpacing.xl),
                const Divider(),
                const SizedBox(height: ESpacing.lg),
                _ShopSection(controller: controller),
              ],
              const SizedBox(height: ESpacing.xl),
            ],
          ),
        );
      }),
    );
  }
}

// ── Header with period toggle ─────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Analytics', style: ETextStyles.h2)),
        Obx(() => _PeriodChip(
              label: 'Weekly',
              active: controller.period.value == 'week',
              onTap: () => controller.setPeriod('week'),
            )),
        const SizedBox(width: ESpacing.xs),
        Obx(() => _PeriodChip(
              label: 'Monthly',
              active: controller.period.value == 'month',
              onTap: () => controller.setPeriod('month'),
            )),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: ESpacing.md, vertical: ESpacing.xs),
        decoration: BoxDecoration(
          color: active ? EColors.primary : EColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: ETextStyles.bodyMd.copyWith(
            color: active ? Colors.white : EColors.onSurfaceMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── KPI cards ─────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpis});
  final Map<String, dynamic> kpis;

  @override
  Widget build(BuildContext context) {
    final fmt      = NumberFormat.simpleCurrency(decimalDigits: 0);
    final revenue  = (kpis['revenue_30d'] as num?)?.toDouble() ?? 0;
    final bookings = (kpis['bookings_30d'] as num?)?.toInt() ?? 0;
    final avg      = (kpis['avg_booking_value'] as num?)?.toDouble() ?? 0;

    return Wrap(
      spacing: ESpacing.md,
      runSpacing: ESpacing.md,
      children: [
        _KpiCard(
          label: 'Revenue (30d)',
          value: fmt.format(revenue),
          icon: Icons.attach_money,
        ),
        _KpiCard(
          label: 'Bookings (30d)',
          value: bookings.toString(),
          icon: Icons.calendar_today_outlined,
        ),
        _KpiCard(
          label: 'Avg Booking Value',
          value: fmt.format(avg),
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(ESpacing.lg),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: EColors.primary),
          const SizedBox(height: ESpacing.sm),
          Text(value, style: ETextStyles.h2),
          const SizedBox(height: ESpacing.xs),
          Text(
            label,
            style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

// ── Shop section ─────────────────────────────────────────────────────────────

class _ShopSection extends StatelessWidget {
  const _ShopSection({required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final fmt      = NumberFormat.simpleCurrency(decimalDigits: 0);
    final kpis     = controller.shopKpis;
    final revenue  = (kpis['revenue_30d'] as num?)?.toDouble() ?? 0;
    final orders   = (kpis['orders_30d'] as num?)?.toInt() ?? 0;
    final avg      = (kpis['avg_order_value'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.store_outlined, size: 20),
          const SizedBox(width: ESpacing.sm),
          Text('Shop', style: ETextStyles.h2),
        ]),
        const SizedBox(height: ESpacing.md),
        Wrap(
          spacing: ESpacing.md,
          runSpacing: ESpacing.md,
          children: [
            _KpiCard(label: 'Shop Revenue (30d)', value: fmt.format(revenue), icon: Icons.attach_money),
            _KpiCard(label: 'Orders (30d)', value: orders.toString(), icon: Icons.shopping_bag_outlined),
            _KpiCard(label: 'Avg Order Value', value: fmt.format(avg), icon: Icons.trending_up),
          ],
        ),
        const SizedBox(height: ESpacing.xl),
        Text('Shop Revenue', style: ETextStyles.h3),
        const SizedBox(height: ESpacing.sm),
        Obx(() => RevenueBarChart(data: controller.shopRevenueByPeriod)),
        const SizedBox(height: ESpacing.xl),
        Text('Top Products (90 days)', style: ETextStyles.h3),
        const SizedBox(height: ESpacing.sm),
        Obx(() => TopProductsChart(data: controller.topProducts)),
      ],
    );
  }
}

// ── Bottom row: top services + busiest days ───────────────────────────────────

class _BottomRow extends StatelessWidget {
  const _BottomRow({required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > ESpacing.mobileBreak;

    final servicesSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Services (90 days)', style: ETextStyles.h3),
        const SizedBox(height: ESpacing.sm),
        Obx(() => TopServicesChart(data: controller.topServices)),
      ],
    );

    final daysSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Busiest Days (90 days)', style: ETextStyles.h3),
        const SizedBox(height: ESpacing.sm),
        Obx(() => BusiestDaysChart(data: controller.busiestDays)),
      ],
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: servicesSection),
          const SizedBox(width: ESpacing.lg),
          Expanded(child: daysSection),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        servicesSection,
        const SizedBox(height: ESpacing.xl),
        daysSection,
      ],
    );
  }
}
