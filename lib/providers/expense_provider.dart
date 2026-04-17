import 'dart:async';
import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseRepository? _repository;
  StreamSubscription<List<Expense>>? _subscription;

  List<Expense> _expenses = [];
  bool _loading = false;
  String? _error;

  ExpenseProvider(this._repository);

  List<Expense> get expenses => _expenses;
  bool get isLoading => _loading;
  String? get error => _error;

  void attachRepository(ExpenseRepository repo) {
    _repository = repo;
  }

  void bindExpenses(String uid) {
    _subscription?.cancel();
    _loading = true;
    notifyListeners();
    _subscription = _repository!.watchExpenses(uid).listen((data) {
      _expenses = data;
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> addExpense(Expense expense) async {
    await _repository!.addExpense(expense);
  }

  Future<void> updateExpense(Expense expense) async {
    await _repository!.updateExpense(expense);
  }

  Future<void> deleteExpense(String uid, String expenseId) async {
    await _repository!.deleteExpense(uid, expenseId);
  }

  double get totalThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => AppDateUtils.isSameMonth(e.date, now))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalToday {
    final now = DateTime.now();
    return _expenses
        .where((e) => AppDateUtils.isSameDay(e.date, now))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> totalsByCategory() {
    final Map<String, double> totals = {};
    for (final expense in _expenses) {
      totals[expense.categoryId] = (totals[expense.categoryId] ?? 0) + expense.amount;
    }
    return totals;
  }

  Map<String, double> last7DaysTotals() {
    final now = DateTime.now();
    final Map<String, double> totals = {};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = '${date.month}/${date.day}';
      
      final dayTotal = _expenses
          .where((e) => AppDateUtils.isSameDay(e.date, date))
          .fold<double>(0.0, (sum, e) => sum + e.amount);
      
      totals[dayKey] = dayTotal;
    }

    return totals;
  }

  int get expenseCountThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => AppDateUtils.isSameMonth(e.date, now))
        .length;
  }

  String? get topCategoryId {
    if (_expenses.isEmpty) return null;
    
    final totals = totalsByCategory();
    if (totals.isEmpty) return null;
    
    String? topId;
    double maxAmount = 0;
    
    for (final entry in totals.entries) {
      if (entry.value > maxAmount) {
        maxAmount = entry.value;
        topId = entry.key;
      }
    }
    
    return topId;
  }

  void clear() {
    _subscription?.cancel();
    _expenses = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}