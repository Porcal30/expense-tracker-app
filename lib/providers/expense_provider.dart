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

  String _searchQuery = '';
  String? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String _sortBy = 'date_desc';

  ExpenseProvider(this._repository);

  List<Expense> get expenses => _expenses;
  bool get isLoading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;
  String get sortBy => _sortBy;

  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategoryId != null ||
        _startDate != null ||
        _endDate != null ||
        _minAmount != null ||
        _maxAmount != null ||
        _sortBy != 'date_desc';
  }

  List<Expense> get filteredExpenses {
    var filtered = _expenses;

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((expense) {
        final titleMatch = expense.title.toLowerCase().contains(query);
        final noteMatch = (expense.note ?? '').toLowerCase().contains(query);
        return titleMatch || noteMatch;
      }).toList();
    }

    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      filtered = filtered
          .where((expense) => expense.categoryId == _selectedCategoryId)
          .toList();
    }

    if (_startDate != null) {
      filtered = filtered
          .where((expense) => !expense.date.isBefore(_startDate!))
          .toList();
    }

    if (_endDate != null) {
      filtered = filtered
          .where((expense) => !expense.date.isAfter(_endDate!))
          .toList();
    }

    if (_minAmount != null) {
      filtered = filtered
          .where((expense) => expense.amount >= _minAmount!)
          .toList();
    }

    if (_maxAmount != null) {
      filtered = filtered
          .where((expense) => expense.amount <= _maxAmount!)
          .toList();
    }

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          return a.date.compareTo(b.date);
        case 'amount_desc':
          return b.amount.compareTo(a.amount);
        case 'amount_asc':
          return a.amount.compareTo(b.amount);
        case 'date_desc':
        default:
          return b.date.compareTo(a.date);
      }
    });

    return filtered;
  }

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

  void setSearchQuery(String query) {
    final normalized = query.trim();
    if (_searchQuery == normalized) return;
    _searchQuery = normalized;
    notifyListeners();
  }

  void setSelectedCategoryId(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setAmountRange(double? min, double? max) {
    _minAmount = min;
    _maxAmount = max;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) return;
    _sortBy = sortBy;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;
    _sortBy = 'date_desc';
    notifyListeners();
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
      totals[expense.categoryId] =
          (totals[expense.categoryId] ?? 0) + expense.amount;
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
    return _expenses.where((e) => AppDateUtils.isSameMonth(e.date, now)).length;
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
    _searchQuery = '';
    _selectedCategoryId = null;
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;
    _sortBy = 'date_desc';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
