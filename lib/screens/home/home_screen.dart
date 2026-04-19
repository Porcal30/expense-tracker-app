import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/recurring_expense_provider.dart';
import '../../screens/expenses/add_edit_expense_screen.dart';
import '../../widgets/budget_dashboard.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // After first frame so ProxyProviders have attached repositories.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
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
    final expenses = expenseProvider.expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddEditExpenseRoute.navigateToAdd(context),
        child: const Icon(Icons.add),
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
                      value: CurrencyUtils.format(expenseProvider.totalThisMonth),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Budget Dashboard
              BudgetDashboard(),
              const SizedBox(height: 24),
              // Expenses section
              expenses.isEmpty
                  ? EmptyState(
                      icon: Icons.wallet_outlined,
                      title: 'No expenses yet',
                      message: 'Tap the + button below to add your first expense',
                      actionButtonLabel: 'Add Expense',
                      actionButtonOnPressed: () =>
                          AddEditExpenseRoute.navigateToAdd(context),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: 'Recent Expenses'),
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
          NavigationDestination(icon: Icon(Icons.category), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}