import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../screens/budget/set_budget_screen.dart';

class BudgetDashboard extends StatelessWidget {
  const BudgetDashboard({super.key});

  void _openSetBudgetScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SetBudgetScreen()),
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

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    // Show loading state while fetching budget
    if (budgetProvider.loading) {
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

    // Show "Set Budget" message if no budget exists
    if (!budgetProvider.hasBudget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Period Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Monthly'),
                      selected: budgetProvider.selectedPeriodType == 'monthly',
                      onSelected: (selected) {
                        if (selected) {
                          _switchPeriod(
                            context,
                            'monthly',
                            budgetProvider.selectedPeriodType,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Weekly'),
                      selected: budgetProvider.selectedPeriodType == 'weekly',
                      onSelected: (selected) {
                        if (selected) {
                          _switchPeriod(
                            context,
                            'weekly',
                            budgetProvider.selectedPeriodType,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Card(
              margin: const EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wallet,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Budget Set',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set a budget for ${budgetProvider.selectedPeriodType == 'monthly' ? 'this month' : 'this week'}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _openSetBudgetScreen(context),
                      child: const Text('Set Budget'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final totalBudget = budgetProvider.totalBudget;
    final totalSpent = budgetProvider.totalSpent;
    final remaining = budgetProvider.remainingBudget;
    final percentage = budgetProvider.budgetPercentage;
    final isOverBudget = budgetProvider.isOverBudget;
    final friendlyLabel = budgetProvider.currentPeriodDisplayLabel;
    final periodType = budgetProvider.selectedPeriodType;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Monthly'),
                        selected: periodType == 'monthly',
                        onSelected: (selected) {
                          if (selected) {
                            _switchPeriod(context, 'monthly', periodType);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Weekly'),
                        selected: periodType == 'weekly',
                        onSelected: (selected) {
                          if (selected) {
                            _switchPeriod(context, 'weekly', periodType);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Total Budget Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friendlyLabel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _openSetBudgetScreen(context),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Budget',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '₱${totalBudget.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Spent',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '₱${totalSpent.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isOverBudget ? Colors.red : Colors.blue,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}% used',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '₱${remaining.toStringAsFixed(2)} remaining',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: remaining < 0 ? Colors.red : Colors.green,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Budgets Section
            if (categoryProvider.categories.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...categoryProvider.categories.map((category) {
                    final categoryBudget = budgetProvider.getCategoryBudget(category.id);
                    if (categoryBudget == 0) return const SizedBox.shrink();

                    final categorySpent = budgetProvider.getCategorySpent(category.id);
                    final categoryPercentage = budgetProvider.getCategoryPercentage(category.id);
                    final isCategoryOverBudget =
                        budgetProvider.isCategoryBudgetExceeded(category.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    category.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    '${(categoryPercentage * 100).toStringAsFixed(0)}%',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: categoryPercentage,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCategoryOverBudget ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₱${categorySpent.toStringAsFixed(2)} / ₱${categoryBudget.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (isCategoryOverBudget)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Over by ₱${(categorySpent - categoryBudget).toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
