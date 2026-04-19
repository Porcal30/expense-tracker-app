import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';

class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({super.key});

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  final _totalBudgetController = TextEditingController();
  final _categoryControllers = <String, TextEditingController>{};
  bool _isSaving = false;

  static Widget _pesoPrefix(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Align(
        widthFactor: 1,
        alignment: Alignment.centerLeft,
        child: Text(
          '₱',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadBudgetData();
  }

  void _initializeControllers() {
    final categories = context.read<CategoryProvider>().categories;

    for (final category in categories) {
      _categoryControllers[category.id] = TextEditingController();
    }
  }

  Future<void> _loadBudgetData() async {
    final auth = context.read<AuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    if (auth.isAuthenticated && auth.user != null) {
      await budgetProvider.loadBudget(auth.user!.uid);

      if (mounted) {
        _populateFormWithBudget();
      }
    }
  }

  void _populateFormWithBudget() {
    final budget = context.read<BudgetProvider>().currentBudget;

    if (budget != null) {
      _totalBudgetController.text = budget.totalBudget.toString();
    } else {
      _totalBudgetController.clear();
    }

    for (final entry in _categoryControllers.entries) {
      final categoryId = entry.key;
      final controller = entry.value;
      final amount = budget?.categoryBudgets[categoryId] ?? 0.0;
      controller.text = amount > 0 ? amount.toString() : '';
    }
  }

  Future<void> _switchPeriodType(int index) async {
    final newPeriodType = index == 0 ? 'monthly' : 'weekly';
    final budgetProvider = context.read<BudgetProvider>();
    if (budgetProvider.selectedPeriodType == newPeriodType) return;

    _totalBudgetController.clear();
    for (final controller in _categoryControllers.values) {
      controller.clear();
    }

    final auth = context.read<AuthProvider>();

    if (auth.isAuthenticated && auth.user != null) {
      await budgetProvider.setPeriodType(newPeriodType, auth.user!.uid);

      if (mounted) {
        _populateFormWithBudget();
      }
    }
  }

  Future<void> _saveBudget() async {
    final auth = context.read<AuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final totalBudgetStr = _totalBudgetController.text.trim();
    if (totalBudgetStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter total budget'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final totalBudget = double.tryParse(totalBudgetStr);
    if (totalBudget == null || totalBudget < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total budget must be a positive number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final categoryBudgets = <String, double>{};
    for (final entry in _categoryControllers.entries) {
      final amount = double.tryParse(entry.value.text.trim());
      if (amount != null && amount > 0) {
        categoryBudgets[entry.key] = amount;
      }
    }

    setState(() => _isSaving = true);

    try {
      final uid = auth.user!.uid;

      debugPrint('[SetBudgetScreen] ======== SAVE BUDGET FLOW START ========');
      debugPrint('[SetBudgetScreen] User UID: $uid');
      debugPrint(
        '[SetBudgetScreen] Period Type: ${budgetProvider.selectedPeriodType}',
      );
      debugPrint('[SetBudgetScreen] User authenticated: ${auth.isAuthenticated}');
      debugPrint('[SetBudgetScreen] Total Budget: $totalBudget');
      debugPrint('[SetBudgetScreen] Category Budgets: $categoryBudgets');

      await budgetProvider.saveBudget(uid, totalBudget, categoryBudgets);

      if (mounted) {
        debugPrint('[SetBudgetScreen] Budget save completed successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget saved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[SetBudgetScreen] ======== SAVE BUDGET FLOW FAILED ========');
      debugPrint('[SetBudgetScreen] Error: $e');
      debugPrint('[SetBudgetScreen] Error type: ${e.runtimeType}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final budgetProvider = context.watch<BudgetProvider>();
    final periodLabel = budgetProvider.currentPeriodDisplayLabel;
    final periodType = budgetProvider.selectedPeriodType;
    final theme = Theme.of(context);
    final periodIndex = periodType == 'monthly' ? 0 : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Budget'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              periodLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                        final gap = 8.0;
                        final segmentWidth = (constraints.maxWidth - gap) / 2;
                        return ToggleButtons(
                          borderRadius: BorderRadius.circular(12),
                          selectedBorderColor: theme.colorScheme.primary,
                          fillColor: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.35),
                          color: theme.colorScheme.onSurface,
                          selectedColor: theme.colorScheme.onPrimaryContainer,
                          highlightColor: Colors.transparent,
                          splashColor:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          constraints: BoxConstraints(
                            minWidth: segmentWidth,
                            maxWidth: segmentWidth,
                            minHeight: 44,
                          ),
                          isSelected: [
                            periodIndex == 0,
                            periodIndex == 1,
                          ],
                          onPressed: _isSaving
                              ? null
                              : (i) => _switchPeriodType(i),
                          children: const [
                            Text('Monthly'),
                            Text('Weekly'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ${periodType == 'monthly' ? 'monthly' : 'weekly'} budget',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _totalBudgetController,
                      label: 'Total budget',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: !_isSaving,
                      prefixIcon: _pesoPrefix(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (categories.isNotEmpty) ...[
              Text(
                'Category budgets (optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...categories.map((category) {
                final controller = _categoryControllers[category.id] ??
                    TextEditingController();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            controller: controller,
                            label: 'Budget for ${category.name}',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            enabled: !_isSaving,
                            prefixIcon: _pesoPrefix(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            LoadingButton(
              label: 'Save budget',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveBudget,
            ),
          ],
        ),
      ),
    );
  }
}
