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
  late String _selectedPeriodType; // 'monthly' or 'weekly'

  @override
  void initState() {
    super.initState();
    _selectedPeriodType = context.read<BudgetProvider>().selectedPeriodType;
    _initializeControllers();
    _loadBudgetData();
  }

  void _initializeControllers() {
    final categories = context.read<CategoryProvider>().categories;
    
    // Create empty controllers for all categories
    for (final category in categories) {
      _categoryControllers[category.id] = TextEditingController();
    }
  }

  Future<void> _loadBudgetData() async {
    final auth = context.read<AuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    
    if (auth.isAuthenticated && auth.user != null) {
      // Ensure budget for current period is loaded
      await budgetProvider.loadBudget(auth.user!.uid);
      
      // Once loaded, populate the form
      if (mounted) {
        _populateFormWithBudget();
      }
    }
  }

  void _populateFormWithBudget() {
    final budget = context.read<BudgetProvider>().currentBudget;
    
    // Update total budget
    if (budget != null) {
      _totalBudgetController.text = budget.totalBudget.toString();
    } else {
      _totalBudgetController.clear();
    }

    // Update category budgets
    for (final entry in _categoryControllers.entries) {
      final categoryId = entry.key;
      final controller = entry.value;
      final amount = budget?.categoryBudgets[categoryId] ?? 0.0;
      controller.text = amount > 0 ? amount.toString() : '';
    }
  }

  Future<void> _switchPeriodType(String newPeriodType) async {
    if (_selectedPeriodType == newPeriodType) return;

    // Clear form to avoid confusion
    _totalBudgetController.clear();
    for (final controller in _categoryControllers.values) {
      controller.clear();
    }

    // Update provider to new period type
    final budgetProvider = context.read<BudgetProvider>();
    final auth = context.read<AuthProvider>();
    
    setState(() {
      _selectedPeriodType = newPeriodType;
    });

    // Load budget for new period type
    if (auth.isAuthenticated && auth.user != null) {
      await budgetProvider.setPeriodType(newPeriodType, auth.user!.uid);
      
      // Populate form with loaded budget
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

    // Build category budgets
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
      debugPrint('[SetBudgetScreen] Period Type: $_selectedPeriodType');
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

        // Pop back to previous screen
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
    final friendlyLabel = budgetProvider.currentPeriodDisplayLabel;

    return Scaffold(
      appBar: AppBar(title: Text('Set Budget - $friendlyLabel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Type Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Period',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Monthly'),
                            selected: _selectedPeriodType == 'monthly',
                            onSelected: (_isSaving)
                                ? null
                                : (selected) => _switchPeriodType('monthly'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Weekly'),
                            selected: _selectedPeriodType == 'weekly',
                            onSelected: (_isSaving)
                                ? null
                                : (selected) => _switchPeriodType('weekly'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Total Budget Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ${_selectedPeriodType == 'monthly' ? 'Monthly' : 'Weekly'} Budget',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      friendlyLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _totalBudgetController,
                      label: 'Total Budget',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: !_isSaving,
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Budgets Section
            if (categories.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Budgets (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: controller,
                                label: 'Budget for ${category.name}',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                enabled: !_isSaving,
                                prefixIcon: const Icon(Icons.attach_money),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            const SizedBox(height: 24),

            // Save Button
            LoadingButton(
              label: 'Save Budget',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveBudget,
            ),
          ],
        ),
      ),
    );
  }
}
