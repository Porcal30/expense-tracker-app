import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency_utils.dart';
import '../data/models/budget_alert.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../screens/budget/budget_history_screen.dart';
import '../screens/budget/set_budget_screen.dart';

/// Color by usage % (0–50 green, 50–80 amber, 80–100 deep orange, >100 red).
Color budgetCategorySeverityColor(double percentUsed) {
  if (percentUsed < 50) return Colors.green.shade700;
  if (percentUsed < 80) return Colors.orange.shade700;
  if (percentUsed <= 100) return Colors.deepOrange.shade700;
  return Colors.red.shade700;
}

class BudgetDashboard extends StatefulWidget {
  const BudgetDashboard({super.key});

  @override
  State<BudgetDashboard> createState() => _BudgetDashboardState();
}

class _BudgetDashboardState extends State<BudgetDashboard> {
  bool _loadScheduled = false;
  bool _showAllCategoryAlerts = false;

  void _scheduleBudgetLoadIfNeeded() {
    if (_loadScheduled) return;

    final auth = context.read<AuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    if (!auth.isAuthenticated || auth.user == null) {
      return;
    }

    if (budgetProvider.isLoading || budgetProvider.hasLoadedCurrentPeriod) {
      return;
    }

    _loadScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;

        final auth = context.read<AuthProvider>();
        final budgetProvider = context.read<BudgetProvider>();

        if (!auth.isAuthenticated || auth.user == null) return;
        if (budgetProvider.isLoading || budgetProvider.hasLoadedCurrentPeriod) {
          return;
        }

        debugPrint(
          '[BudgetDashboard] Triggering loadCurrentBudget for uid=${auth.user!.uid}, '
          'period=${budgetProvider.selectedPeriodType}',
        );

        await budgetProvider.loadCurrentBudget(auth.user!.uid);
      } finally {
        if (mounted) {
          _loadScheduled = false;
        }
      }
    });
  }

  void _openSetBudgetScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SetBudgetScreen()),
    );
  }

  void _openBudgetHistory(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const BudgetHistoryScreen()),
    );
  }

  Future<void> _switchPeriod(
    BuildContext context,
    String newPeriodType,
    String currentPeriodType,
  ) async {
    if (newPeriodType == currentPeriodType) return;

    final budgetProvider = context.read<BudgetProvider>();
    final auth = context.read<AuthProvider>();

    if (auth.isAuthenticated && auth.user != null) {
      try {
        setState(() {
          _showAllCategoryAlerts = false;
        });
        await budgetProvider.setPeriodType(newPeriodType, auth.user!.uid);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to switch period: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _periodToggle(
    BuildContext context, {
    required String periodType,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    final index = periodType == 'monthly' ? 0 : 1;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget period',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final segmentWidth = (constraints.maxWidth - gap) / 2;
                return ToggleButtons(
                  borderRadius: BorderRadius.circular(12),
                  selectedBorderColor: theme.colorScheme.primary,
                  fillColor: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  color: theme.colorScheme.onSurface,
                  selectedColor: theme.colorScheme.onPrimaryContainer,
                  highlightColor: Colors.transparent,
                  splashColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  constraints: BoxConstraints(
                    minWidth: segmentWidth,
                    maxWidth: segmentWidth,
                    minHeight: 44,
                  ),
                  isSelected: [index == 0, index == 1],
                  onPressed: enabled
                      ? (i) {
                          _switchPeriod(
                            context,
                            i == 0 ? 'monthly' : 'weekly',
                            periodType,
                          );
                        }
                      : null,
                  children: const [Text('Monthly'), Text('Weekly')],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    final theme = Theme.of(context);
    final textAlign = align == CrossAxisAlignment.end
        ? TextAlign.end
        : align == CrossAxisAlignment.center
            ? TextAlign.center
            : TextAlign.start;

    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            textAlign: textAlign,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: textAlign,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _budgetAlertCard(BuildContext context, BudgetAlert alert) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (alert.severity) {
      case BudgetAlertSeverity.info:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade900;
        icon = Icons.info_outline;
        break;
      case BudgetAlertSeverity.warning:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        icon = Icons.warning_amber_rounded;
        break;
      case BudgetAlertSeverity.danger:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        icon = Icons.error_outline;
        break;
    }

    return Card(
      color: backgroundColor,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                alert.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryAlertsSection(
    BuildContext context,
    List<CategoryBudgetAlert> alerts,
    CategoryProvider categoryProvider,
  ) {
    final visibleAlerts = _showAllCategoryAlerts ? alerts : alerts.take(2).toList();
    final remainingCount = alerts.length - visibleAlerts.length;
    final theme = Theme.of(context);

    Widget buildAlertCard(CategoryBudgetAlert alert) {
      final category = categoryProvider.getById(alert.categoryId);
      final categoryName = category?.name ?? 'Unknown category';

      Color backgroundColor;
      Color textColor;
      IconData icon;

      switch (alert.severity) {
        case BudgetAlertSeverity.info:
          backgroundColor = Colors.blue.shade50;
          textColor = Colors.blue.shade900;
          icon = Icons.info_outline;
          break;
        case BudgetAlertSeverity.warning:
          backgroundColor = Colors.orange.shade50;
          textColor = Colors.orange.shade900;
          icon = Icons.warning_amber_rounded;
          break;
        case BudgetAlertSeverity.danger:
          backgroundColor = Colors.red.shade50;
          textColor = Colors.red.shade900;
          icon = Icons.error_outline;
          break;
      }

      return Card(
        color: backgroundColor,
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$categoryName: ${alert.message}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Category alerts',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...visibleAlerts.map(buildAlertCard),
        if (!_showAllCategoryAlerts && remainingCount > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllCategoryAlerts = true;
                });
              },
              icon: const Icon(Icons.expand_more),
              label: Text('+$remainingCount more warning${remainingCount == 1 ? '' : 's'}'),
            ),
          ),
        if (_showAllCategoryAlerts && alerts.length > 2)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllCategoryAlerts = false;
                });
              },
              icon: const Icon(Icons.expand_less),
              label: const Text('Show less'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    _scheduleBudgetLoadIfNeeded();

    debugPrint(
      '[BudgetDashboard] isAuthenticated=${auth.isAuthenticated}, '
      'isLoading=${budgetProvider.isLoading}, '
      'hasLoadedCurrentPeriod=${budgetProvider.hasLoadedCurrentPeriod}, '
      'hasBudget=${budgetProvider.hasBudget}, '
      'period=${budgetProvider.selectedPeriodType}',
    );

    final periodType = budgetProvider.selectedPeriodType;

    if (!auth.isAuthenticated || auth.user == null) {
      return const SizedBox.shrink();
    }

    if (budgetProvider.isLoading || !budgetProvider.hasLoadedCurrentPeriod) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading budget...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (!budgetProvider.hasBudget) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _periodToggle(context, periodType: periodType, enabled: true),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wallet_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No budget set',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      budgetProvider.currentPeriodDisplayLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a budget for this period to track spending.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => _openSetBudgetScreen(context),
                      child: const Text('Set budget'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _openBudgetHistory(context),
                      child: const Text('View budget history'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final totalBudget = budgetProvider.totalBudget;
    final totalSpent = budgetProvider.totalSpent;
    final remaining = budgetProvider.remainingBudget;
    final percentage = budgetProvider.budgetPercentage;
    final isOverBudget = budgetProvider.isOverBudget;
    final friendlyLabel = budgetProvider.currentPeriodDisplayLabel;
    final theme = Theme.of(context);
    final green = Colors.green.shade700;
    final red = theme.colorScheme.error;

    final spentShare = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final percentUsedLabel = totalBudget > 0
        ? '${(spentShare * 100).toStringAsFixed(1)}% used'
        : '0% used';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _periodToggle(context, periodType: periodType, enabled: true),
            if (budgetProvider.wasAutoCopied) ...[
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.primaryContainer,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    periodType == 'weekly'
                        ? "This week's budget was copied from last week."
                        : "This month's budget was copied from last month.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            if (budgetProvider.overallBudgetAlert != null) ...[
              _budgetAlertCard(context, budgetProvider.overallBudgetAlert!),
              const SizedBox(height: 16),
            ],
            if (budgetProvider.categoryAlerts.isNotEmpty) ...[
              _categoryAlertsSection(
                context,
                budgetProvider.categoryAlerts,
                categoryProvider,
              ),
              const SizedBox(height: 16),
            ],
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            friendlyLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openBudgetHistory(context),
                          child: const Text('View history'),
                        ),
                        TextButton.icon(
                          onPressed: () => _openSetBudgetScreen(context),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryMetric(
                          context,
                          label: 'Total budget',
                          value: CurrencyUtils.format(totalBudget),
                          valueColor: green,
                        ),
                        const SizedBox(width: 12),
                        _summaryMetric(
                          context,
                          label: 'Spent',
                          value: CurrencyUtils.format(totalSpent),
                          valueColor: isOverBudget
                              ? red
                              : theme.colorScheme.tertiary,
                          align: CrossAxisAlignment.center,
                        ),
                        const SizedBox(width: 12),
                        _summaryMetric(
                          context,
                          label: 'Remaining',
                          value: CurrencyUtils.format(remaining),
                          valueColor: remaining <= 0 && totalBudget > 0
                              ? red
                              : green,
                          align: CrossAxisAlignment.end,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 10,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget ? red : green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      percentUsedLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (categoryProvider.categories.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category breakdown',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...() {
                    final sorted = categoryProvider.categories
                        .where((c) => budgetProvider.getCategoryBudget(c.id) > 0)
                        .toList()
                      ..sort((a, b) {
                        final ba = budgetProvider.getCategoryBudget(a.id);
                        final bb = budgetProvider.getCategoryBudget(b.id);
                        final ra = budgetProvider.getCategorySpent(a.id) / ba;
                        final rb = budgetProvider.getCategorySpent(b.id) / bb;
                        return rb.compareTo(ra);
                      });

                    return sorted.map((category) {
                      final categoryBudget =
                          budgetProvider.getCategoryBudget(category.id);
                      final categorySpent =
                          budgetProvider.getCategorySpent(category.id);
                      final ratio = categoryBudget > 0
                          ? categorySpent / categoryBudget
                          : 0.0;
                      final categoryBarValue = ratio.clamp(0.0, 1.0);
                      final categoryPercentUsed = ratio * 100;
                      final severity =
                          budgetCategorySeverityColor(categoryPercentUsed);
                      final isCategoryOverBudget =
                          budgetProvider.isCategoryBudgetExceeded(category.id);
                      final overBy = categorySpent - categoryBudget;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        category.name,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${categoryPercentUsed.toStringAsFixed(0)}%',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: severity,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: categoryBarValue,
                                    minHeight: 8,
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      severity,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${CurrencyUtils.format(categorySpent)} / ${CurrencyUtils.format(categoryBudget)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color:
                                              theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (isCategoryOverBudget) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: severity.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Over by ${CurrencyUtils.format(overBy)}',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: severity,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  }(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}