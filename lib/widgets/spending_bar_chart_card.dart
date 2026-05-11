import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/currency_utils.dart';
import '../providers/expense_provider.dart';

class SpendingBarChartCard extends StatelessWidget {
  final ExpenseProvider expenseProvider;

  const SpendingBarChartCard({super.key, required this.expenseProvider});

  @override
  Widget build(BuildContext context) {
    final last7Days = expenseProvider.last7DaysTotals();
    final entries = last7Days.entries.toList();

    final maxAmount = last7Days.values.fold<double>(
      0,
      (max, val) => val > max ? val : max,
    );

    final peakIndex = entries.indexWhere((e) => e.value == maxAmount);

    const weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final barGroups = entries.asMap().entries.map((e) {
      final index = e.key;
      final entry = e.value;
      final isPeak = index == peakIndex;

      return BarChartGroupData(
        x: index,
        barsSpace: 0,
        showingTooltipIndicators: isPeak ? [1] : const [],
        barRods: [
          BarChartRodData(
            toY: maxAmount > 0 ? maxAmount * 1.18 : 100,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.06),
            width: 17,
            borderRadius: BorderRadius.circular(14),
          ),
          BarChartRodData(
            toY: entry.value,
            gradient: LinearGradient(
              colors: isPeak
                  ? [const Color(0xFF4AE9FF), const Color(0xFF4A78FF)]
                  : [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.primary,
                    ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: isPeak ? 20 : 17,
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: isPeak ? 0.35 : 0.15),
              width: 1,
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xD6172F57), Color(0xD20D1A34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.16),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.65),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Last 7 Days Pulse',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                swapAnimationDuration: const Duration(milliseconds: 950),
                swapAnimationCurve: Curves.easeOutExpo,
                BarChartData(
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      getTooltipColor: (_) => const Color(0xFF0B1229),
                      fitInsideHorizontally: true,
                      getTooltipItem: (group, _, rod, __) {
                        if (rod.toY <= 0) {
                          return null;
                        }
                        return BarTooltipItem(
                          CurrencyUtils.format(rod.toY),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                      strokeWidth: 1,
                      dashArray: [4, 5],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 72,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              CurrencyUtils.format(value.toDouble()),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 9,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }

                          final key = entries[index].key;
                          final parts = key.split('/');

                          int month = 1;
                          int day = 1;

                          if (parts.length == 2) {
                            month = int.tryParse(parts[0]) ?? 1;
                            day = int.tryParse(parts[1]) ?? 1;
                          }

                          final now = DateTime.now();
                          final date = DateTime(now.year, month, day);
                          final label = weekdayLabels[date.weekday % 7];

                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: index == peakIndex
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  minY: 0,
                  maxY: maxAmount > 0 ? maxAmount * 1.18 : 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
