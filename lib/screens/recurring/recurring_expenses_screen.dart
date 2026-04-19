import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_utils.dart';
import '../../data/models/recurring_expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recurring_expense_provider.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_recurring_expense_screen.dart';

class RecurringExpensesScreen extends StatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  State<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.user != null) {
        context.read<RecurringExpenseProvider>().bindRecurringExpenses(auth.user!.uid);
      }
    });
  }

  String _frequencyLabel(String code) {
    switch (code) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return code;
    }
  }

  Future<void> _openEditor({RecurringExpense? template}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddEditRecurringExpenseScreen(template: template),
      ),
    );
  }

  Future<void> _confirmDelete(RecurringExpense item) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recurring expense'),
        content: Text('Remove "${item.title}"? This does not delete past expenses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<RecurringExpenseProvider>().deleteRecurringExpense(uid, item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring expense deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not delete. Try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecurringExpenseProvider>();
    final items = provider.recurringExpenses;
    final dateFmt = DateFormat.yMMMd();

    Widget body;

    if (provider.isLoading && items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && items.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load recurring expenses.\n${provider.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (items.isEmpty) {
      body = EmptyState(
        icon: Icons.repeat,
        title: 'No recurring expenses',
        message:
            'Add subscriptions, rent, or other repeating bills. When due, they appear in your expense list automatically.',
        actionButtonLabel: 'Add recurring expense',
        actionButtonOnPressed: () => _openEditor(),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final activeColor = item.isActive ? Colors.green.shade700 : Colors.grey.shade600;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyUtils.format(item.amount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_frequencyLabel(item.frequency)} · Starts ${dateFmt.format(item.startDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: activeColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              isThreeLine: true,
              onTap: () => _openEditor(template: item),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditor(template: item);
                  } else if (value == 'delete') {
                    _confirmDelete(item);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring expenses'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}
