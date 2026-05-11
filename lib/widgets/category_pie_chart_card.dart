import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/currency_utils.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';

class CategoryPieChartCard extends StatefulWidget {
  final ExpenseProvider expenseProvider;
  final CategoryProvider categoryProvider;

  const CategoryPieChartCard({
    super.key,
    required this.expenseProvider,
    required this.categoryProvider,
  });

  @override
  State<CategoryPieChartCard> createState() => _CategoryPieChartCardState();
}

class _CategoryPieChartCardState extends State<CategoryPieChartCard> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final totals = widget.expenseProvider.totalsByCategory();
    final filteredTotals = Map.fromEntries(
      totals.entries.where((e) => e.value > 0),
    );

    if (filteredTotals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No category data',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    final entries = filteredTotals.entries.toList();
    final total = filteredTotals.values.fold<double>(0, (a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xD8141F42), Color(0xD8132C53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.secondary.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.blur_circular,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spending Constellation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 188,
                    height: 188,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  PieChart(
                    swapAnimationDuration: const Duration(milliseconds: 900),
                    swapAnimationCurve: Curves.easeOutCubic,
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response?.touchedSection == null) {
                            setState(() => touchedIndex = -1);
                            return;
                          }
                          setState(() {
                            touchedIndex =
                                response!.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: entries.asMap().entries.map((entryWrap) {
                        final index = entryWrap.key;
                        final categoryId = entryWrap.value.key;
                        final amount = entryWrap.value.value;
                        final percentage = amount / total * 100;
                        final category = widget.categoryProvider.getById(
                          categoryId,
                        );
                        final baseColor = Color(
                          category?.colorValue ?? 0xFF9E9E9E,
                        );
                        final isTouched = index == touchedIndex;

                        return PieChartSectionData(
                          value: amount,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: isTouched ? 72 : (percentage >= 20 ? 63 : 56),
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 14 : 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          color: baseColor,
                          gradient: LinearGradient(
                            colors: [
                              baseColor.withValues(alpha: 0.9),
                              baseColor.withValues(alpha: 0.62),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          badgeWidget: percentage >= 22
                              ? Container(
                                  width: isTouched ? 10 : 7,
                                  height: isTouched ? 10 : 7,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        );
                      }).toList(),
                      centerSpaceRadius: 52,
                      centerSpaceColor: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.76),
                      sectionsSpace: 4,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        touchedIndex >= 0
                            ? (widget.categoryProvider
                                      .getById(entries[touchedIndex].key)
                                      ?.name ??
                                  'Category')
                            : 'TOTAL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.format(
                          touchedIndex >= 0
                              ? entries[touchedIndex].value
                              : total,
                        ),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) {
              final category = widget.categoryProvider.getById(entry.key);
              final categoryName = category?.name ?? 'Unknown';
              final amount = entry.value;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.03),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(category?.colorValue ?? 0xFF9E9E9E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        categoryName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        CurrencyUtils.format(amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
