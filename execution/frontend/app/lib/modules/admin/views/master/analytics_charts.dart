import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';

// ── Revenue bar chart ─────────────────────────────────────────────────────────

class RevenueBarChart extends StatelessWidget {
  const RevenueBarChart({super.key, required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyChart('No revenue data yet');

    final fmt = NumberFormat.compactSimpleCurrency(decimalDigits: 0);
    final maxY = data
            .map((d) => (d['revenue'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b) *
        1.25;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(ESpacing.sm, ESpacing.md, ESpacing.sm, ESpacing.sm),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (e.value['revenue'] as num).toDouble(),
                  color: EColors.primary,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (v, _) => Text(
                  fmt.format(v),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[i]['label'] as String,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                    ),
                  );
                },
              ),
            ),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => EColors.primary,
              getTooltipItem: (_, _, rod, _) => BarTooltipItem(
                fmt.format(rod.toY),
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Busiest days bar chart ────────────────────────────────────────────────────

class BusiestDaysChart extends StatelessWidget {
  const BusiestDaysChart({super.key, required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyChart('No data yet');

    final maxY = data
            .map((d) => (d['count'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b) *
        1.25;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(ESpacing.sm, ESpacing.md, ESpacing.sm, ESpacing.sm),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (e.value['count'] as num).toDouble(),
                  color: EColors.secondary,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[i]['day'] as String,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                ),
              ),
            ),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

// ── Top services horizontal bars ──────────────────────────────────────────────

class TopServicesChart extends StatelessWidget {
  const TopServicesChart({super.key, required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyChart('No service data yet');

    final maxCount = data
        .map((d) => (d['count'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: data.map((svc) {
        final pct = maxCount > 0 ? (svc['count'] as num).toDouble() / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: ESpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(svc['name'] as String, style: ETextStyles.bodyMd),
                ),
                Text(
                  '${svc['count']} bookings',
                  style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
                ),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  color: EColors.primary,
                  backgroundColor: EColors.surface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Top products horizontal bars ─────────────────────────────────────────────

class TopProductsChart extends StatelessWidget {
  const TopProductsChart({super.key, required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyChart('No product data yet');

    final maxCount = data
        .map((d) => (d['sold'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: data.map((product) {
        final pct = maxCount > 0 ? (product['sold'] as num).toDouble() / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: ESpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(product['name'] as String, style: ETextStyles.bodyMd),
                ),
                Text(
                  '${product['sold']} sold',
                  style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
                ),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  color: EColors.secondary,
                  backgroundColor: EColors.surface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  const _EmptyChart(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
      ),
    );
  }
}
