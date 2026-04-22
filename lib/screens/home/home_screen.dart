import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/recurring_expense_provider.dart';
import '../../screens/budget/budget_history_screen.dart';
import '../../screens/expenses/add_edit_expense_screen.dart';
import '../../widgets/budget_dashboard.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/expense_filter_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      context.read<ExpenseProvider>().setSearchQuery(value);
    });

    setState(() {});
  }

  Future<void> _openExpenseFilterSheet() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ExpenseFilterSheet(
          expenseProvider: expenseProvider,
          categories: categoryProvider.categories,
        );
      },
    );

    setState(() {});
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.user != null) {
      final uid = auth.user!.uid;
      final budgetProvider = context.read<BudgetProvider>();
      final recurringProvider = context.read<RecurringExpenseProvider>();
      await budgetProvider.loadAllBudgets(uid);
      if (!mounted) return;
      await recurringProvider.generateDueExpenses(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.filteredExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Budget history',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BudgetHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: FloatingActionButton(
    tooltip: 'Add expense',
    onPressed: () => AddEditExpenseRoute.navigateToAdd(context),
    child: const Icon(Icons.add),
  ),
),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Today',
                      value: CurrencyUtils.format(expenseProvider.totalToday),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'This Month',
                      value: CurrencyUtils.format(
                        expenseProvider.totalThisMonth,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Budget Dashboard
              const BudgetDashboard(),

              const SizedBox(height: 24),

              // Search + Filter (clean UI)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search expenses',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ExpenseProvider>().setSearchQuery('');
                              setState(() {});
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: _openExpenseFilterSheet,
                          tooltip: 'Filters',
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              if (expenseProvider.hasActiveFilters) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Active filters are applied',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          expenseProvider.resetFilters();
                          setState(() {});
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Expenses
              expenses.isEmpty
                  ? EmptyState(
                      icon: Icons.wallet_outlined,
                      title: expenseProvider.expenses.isEmpty
                          ? 'No expenses yet'
                          : 'No expenses match your filters',
                      message: expenseProvider.expenses.isEmpty
                          ? 'Tap the Add Expense button below to add your first expense'
                          : 'Try changing or clearing your search and filters.',
                      actionButtonLabel: 'Add Expense',
                      actionButtonOnPressed: () =>
                          AddEditExpenseRoute.navigateToAdd(context),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Recent Expenses'),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenses.length,
                          itemBuilder: (_, index) =>
                              ExpenseCard(expense: expenses[index]),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) Navigator.pushNamed(context, AppRoutes.reports);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.categories);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.settings);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}