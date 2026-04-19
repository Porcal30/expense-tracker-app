import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/recurrence_helper.dart';
import '../data/models/expense.dart';
import '../data/models/recurring_expense.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/recurring_expense_repository.dart';

class RecurringExpenseProvider extends ChangeNotifier {
  RecurringExpenseRepository? _recurringRepository;
  ExpenseRepository? _expenseRepository;
  StreamSubscription<List<RecurringExpense>>? _subscription;

  List<RecurringExpense> _recurringExpenses = [];
  bool _isLoading = false;
  String? _error;

  RecurringExpenseProvider(this._recurringRepository, this._expenseRepository);

  List<RecurringExpense> get recurringExpenses => _recurringExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void attachRepositories(
    RecurringExpenseRepository recurring,
    ExpenseRepository expense,
  ) {
    _recurringRepository = recurring;
    _expenseRepository = expense;
  }

  void bindRecurringExpenses(String uid) {
    final repo = _recurringRepository;
    if (repo == null) return;

    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = repo.watchRecurringExpenses(uid).listen(
      (data) {
        _recurringExpenses = data;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e, StackTrace stackTrace) {
        debugPrint('bindRecurringExpenses error: $e\n$stackTrace');
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addRecurringExpense(RecurringExpense item) async {
    await _recurringRepository!.addRecurringExpense(item);
  }

  Future<void> updateRecurringExpense(RecurringExpense item) async {
    await _recurringRepository!.updateRecurringExpense(item);
  }

  Future<void> deleteRecurringExpense(String uid, String recurringId) async {
    await _recurringRepository!.deleteRecurringExpense(uid, recurringId);
  }

  /// Creates normal [Expense] rows for due templates and updates [lastGeneratedDate].
  /// Safe to call repeatedly (e.g. on app open).
  Future<void> generateDueExpenses(String uid) async {
    final recurringRepo = _recurringRepository;
    final expenseRepo = _expenseRepository;
    if (recurringRepo == null || expenseRepo == null) return;

    try {
      final templates = await recurringRepo.getRecurringExpenses(uid);
      final now = DateTime.now();

      for (final template in templates) {
        if (!template.isActive) continue;
        if (!RecurrenceHelper.isDue(template, now)) continue;

        final expenseDate = RecurrenceHelper.dateOnly(now);

        final expense = Expense(
          id: const Uuid().v4(),
          userId: uid,
          title: template.title,
          amount: template.amount,
          categoryId: template.categoryId,
          date: expenseDate,
          note: template.note,
          recurringSourceId: template.id,
          createdAt: now,
          updatedAt: now,
        );

        await expenseRepo.addExpense(expense);

        final updatedTemplate = template.copyWith(
          lastGeneratedDate: expenseDate,
          updatedAt: now,
        );
        await recurringRepo.updateRecurringExpense(updatedTemplate);
      }
    } catch (e, st) {
      debugPrint('generateDueExpenses failed: $e\n$st');
    }
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _recurringExpenses = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
