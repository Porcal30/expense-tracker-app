import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency_utils.dart';
import '../data/models/expense.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../screens/expenses/add_edit_expense_screen.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final category = context.watch<CategoryProvider>().getById(
      expense.categoryId,
    );
    final auth = context.read<AuthProvider>();
    final categoryColor = Color(category?.colorValue ?? 0xFF8FA2BE);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => AddEditExpenseRoute.navigateToEdit(context, expense),
        child: ListTile(
          leading: Container(
            width: 12,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Text(expense.title),
          subtitle: Text(
            '${category?.name ?? 'Unknown'} - ${expense.date.toLocal().toString().split(' ').first}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.format(expense.amount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  await context.read<ExpenseProvider>().deleteExpense(
                    auth.user!.uid,
                    expense.id,
                  );
                },
                child: const Icon(Icons.delete, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
