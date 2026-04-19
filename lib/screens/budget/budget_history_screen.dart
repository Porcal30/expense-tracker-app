import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_utils.dart';
import '../../core/utils/period_helper.dart';
import '../../data/models/budget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/empty_state.dart';

enum _HistoryFilter { all, monthly, weekly }

class BudgetHistoryScreen extends StatefulWidget {
  const BudgetHistoryScreen({super.key});

  @override
  State<BudgetHistoryScreen> createState() => _BudgetHistoryScreenState();
}

class _BudgetHistoryScreenState extends State<BudgetHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<BudgetProvider>().loadBudgetHistory(uid);
      }
    });
  }

  List<Budget> _filtered(List<Budget> all) {
    switch (_filter) {
      case _HistoryFilter.all:
        return all;
      case _HistoryFilter.monthly:
        return all.where((b) => b.periodType == 'monthly').toList();
      case _HistoryFilter.weekly:
        return all.where((b) => b.periodType == 'weekly').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    context.watch<ExpenseProvider>();

    final budgetProvider = context.watch<BudgetProvider>();
    final history = budgetProvider.budgetHistory;
    final filtered = _filtered(history);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget history'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<_HistoryFilter>(
              segments: const [
                ButtonSegment(
                  value: _HistoryFilter.all,
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: _HistoryFilter.monthly,
                  label: Text('Monthly'),
                ),
                ButtonSegment(
                  value: _HistoryFilter.weekly,
                  label: Text('Weekly'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
          Expanded(
            child: _buildBody(
              context,
              auth: auth,
              budgetProvider: budgetProvider,
              filtered: filtered,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required AuthProvider auth,
    required BudgetProvider budgetProvider,
    required List<Budget> filtered,
    required ThemeData theme,
  }) {
    if (!auth.isAuthenticated || auth.user == null) {
      return const Center(child: Text('Sign in to view budget history'));
    }

    if (budgetProvider.isHistoryLoading && budgetProvider.budgetHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (budgetProvider.historyError != null &&
        budgetProvider.budgetHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            budgetProvider.historyError!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (budgetProvider.budgetHistory.isEmpty) {
      return EmptyState(
        icon: Icons.history,
        title: 'No budget history yet',
        message:
            'Saved monthly and weekly budgets will appear here with spending for each period.',
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No ${_filter == _HistoryFilter.monthly ? 'monthly' : 'weekly'} budgets saved yet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final uid = auth.user!.uid;
        await budgetProvider.loadBudgetHistory(uid);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final budget = filtered[index];
          final spent = budgetProvider.getTotalSpentForBudget(budget);
          final remaining = budgetProvider.getRemainingForBudget(budget);
          final over = budgetProvider.isOverBudgetFor(budget);
          final periodLabel =
              PeriodHelper.friendlyBudgetHistoryLabel(budget);
          final monthly = budget.periodType == 'monthly';

          final red = theme.colorScheme.error;
          final green = Colors.green.shade700;
          final blue = theme.colorScheme.tertiary;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          periodLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        label: Text(monthly ? 'Monthly' : 'Weekly'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _metricRow(
                    theme,
                    label: 'Total budget',
                    value: CurrencyUtils.format(budget.totalBudget),
                    valueColor: green,
                  ),
                  const SizedBox(height: 8),
                  _metricRow(
                    theme,
                    label: 'Spent',
                    value: CurrencyUtils.format(spent),
                    valueColor: over ? red : blue,
                  ),
                  const SizedBox(height: 8),
                  _metricRow(
                    theme,
                    label: 'Remaining',
                    value: CurrencyUtils.format(remaining),
                    valueColor: remaining >= 0 ? green : red,
                  ),
                  if (over) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Exceeded total budget by ${CurrencyUtils.format(spent - budget.totalBudget)}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metricRow(
    ThemeData theme, {
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
