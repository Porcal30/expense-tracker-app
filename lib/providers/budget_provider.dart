import 'package:flutter/foundation.dart';

import '../core/utils/period_helper.dart';
import '../data/models/budget.dart';
import '../data/repositories/budget_repository.dart';
import 'expense_provider.dart';

class BudgetProvider extends ChangeNotifier {
  BudgetRepository? _repository;
  ExpenseProvider? _expenseProvider;

  // Current period selection
  String _selectedPeriodType = 'monthly'; // 'monthly' or 'weekly'
  
  // Loaded budgets
  Budget? _monthlyBudget;
  Budget? _weeklyBudget;
  
  bool _loading = false;
  String? _error;

  BudgetProvider(this._repository, this._expenseProvider);

  void attachRepositories(BudgetRepository budgetRepository, ExpenseProvider expenseProvider) {
    _repository = budgetRepository;
    _expenseProvider = expenseProvider;
    notifyListeners();
  }

  // ============ GETTERS ============

  String get selectedPeriodType => _selectedPeriodType;
  
  bool get loading => _loading;
  String? get error => _error;
  
  /// Current budget based on selected period type
  Budget? get currentBudget {
    if (_selectedPeriodType == 'monthly') {
      return _monthlyBudget;
    } else {
      return _weeklyBudget;
    }
  }

  bool get hasBudget => currentBudget != null;

  /// Get current period ID based on selected type
  String get currentPeriodId {
    if (_selectedPeriodType == 'monthly') {
      return PeriodHelper.getCurrentMonthId();
    } else {
      return PeriodHelper.getCurrentWeekId();
    }
  }

  /// Get human-readable label for current period
  String get currentPeriodLabel =>
      PeriodHelper.getPeriodLabel(_selectedPeriodType, currentPeriodId);

  /// Get friendly display label for current period
  /// Example:
  /// - "This Week (Apr 14 – Apr 20)" for weekly
  /// - "This Month (April 2026)" for monthly
  String get currentPeriodDisplayLabel =>
      PeriodHelper.getFriendlyPeriodLabel(_selectedPeriodType);

  /// Get budget title for UI display
  /// Example: "This Month (April 2026)" or "This Week (Apr 14 – Apr 20)"
  String get currentBudgetTitle => currentPeriodDisplayLabel;

  /// Total budget amount for current period
  double get totalBudget => currentBudget?.totalBudget ?? 0.0;

  /// Total spent in current period
  double get totalSpent {
    if (_expenseProvider == null) return 0.0;
    
    return _expenseProvider!.expenses
        .where((expense) =>
            PeriodHelper.belongsToPeriod(
              expense.date,
              _selectedPeriodType,
              currentPeriodId,
            ))
        .fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Remaining budget (totalBudget - totalSpent)
  double get remainingBudget => (totalBudget - totalSpent).clamp(0.0, double.infinity);

  /// Percentage of budget used (0.0 to 1.0)
  double get budgetPercentage {
    if (totalBudget == 0.0) return 0.0;
    return (totalSpent / totalBudget).clamp(0.0, 1.0);
  }

  /// Check if overall budget is exceeded
  bool get isOverBudget => totalSpent > totalBudget;

  // ============ CATEGORY METHODS ============

  /// Get budget for a specific category
  double getCategoryBudget(String categoryId) {
    return currentBudget?.categoryBudgets[categoryId] ?? 0.0;
  }

  /// Get spent amount for a specific category in current period
  double getCategorySpent(String categoryId) {
    if (_expenseProvider == null) return 0.0;
    
    return _expenseProvider!.expenses
        .where((expense) =>
            expense.categoryId == categoryId &&
            PeriodHelper.belongsToPeriod(
              expense.date,
              _selectedPeriodType,
              currentPeriodId,
            ))
        .fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get percentage for a specific category (0.0 to 1.0)
  double getCategoryPercentage(String categoryId) {
    final budget = getCategoryBudget(categoryId);
    if (budget == 0.0) return 0.0;
    final spent = getCategorySpent(categoryId);
    return (spent / budget).clamp(0.0, 1.0);
  }

  /// Check if budget is exceeded for a category
  bool isCategoryBudgetExceeded(String categoryId) {
    return getCategorySpent(categoryId) > getCategoryBudget(categoryId);
  }

  // ============ LOAD/SAVE METHODS ============

  /// Set the selected period type and reload budget
  Future<void> setPeriodType(String periodType, String uid) async {
    if (!PeriodHelper.isValidPeriodType(periodType)) {
      throw Exception('Invalid period type: $periodType');
    }

    _selectedPeriodType = periodType;
    notifyListeners();
    
    // Load budget for the new period type
    await loadBudget(uid);
  }

  /// Load budget for current period type
  /// This loads the budget for the current month (if monthly) or current week (if weekly)
  Future<void> loadBudget(String uid) async {
    if (_repository == null) return;

    if (uid.isEmpty) {
      _error = 'Cannot load budget: uid is empty';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final periodId = currentPeriodId;
      
      debugPrint('[BudgetProvider] ======== LOAD BUDGET ========');
      debugPrint('[BudgetProvider] Loading budget for user=$uid, periodType=$_selectedPeriodType, periodId=$periodId');

      final budget = await _repository!.getBudget(uid, _selectedPeriodType, periodId);

      if (_selectedPeriodType == 'monthly') {
        _monthlyBudget = budget;
      } else {
        _weeklyBudget = budget;
      }

      if (budget != null) {
        debugPrint('[BudgetProvider] Budget loaded successfully');
      } else {
        debugPrint('[BudgetProvider] No budget found, create new one');
      }
    } catch (e) {
      debugPrint('[BudgetProvider] Error loading budget: $e');
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Save or update budget for current period
  Future<void> saveBudget(
    String uid,
    double totalBudget,
    Map<String, double> categoryBudgets,
  ) async {
    if (_repository == null) return;

    try {
      // Validate uid and period type
      if (uid.isEmpty) {
        throw Exception('Cannot save budget: uid is empty or null');
      }
      if (!PeriodHelper.isValidPeriodType(_selectedPeriodType)) {
        throw Exception('Cannot save budget: invalid periodType $_selectedPeriodType');
      }

      final periodId = currentPeriodId;
      
      debugPrint('[BudgetProvider] ======== SAVE BUDGET REQUEST ========');
      debugPrint('[BudgetProvider] UID: $uid');
      debugPrint('[BudgetProvider] Period Type: $_selectedPeriodType');
      debugPrint('[BudgetProvider] Period ID: $periodId');
      debugPrint('[BudgetProvider] Period Label: $currentPeriodLabel');
      debugPrint('[BudgetProvider] Total Budget: $totalBudget');
      debugPrint('[BudgetProvider] Category Budgets: $categoryBudgets');

      final budget = Budget(
        userId: uid,
        periodType: _selectedPeriodType,
        periodId: periodId,
        totalBudget: totalBudget,
        categoryBudgets: categoryBudgets,
      );

      debugPrint('[BudgetProvider] Budget object created: $budget');
      debugPrint('[BudgetProvider] Calling repository.setBudget...');

      await _repository!.setBudget(budget);

      // Update the appropriate budget
      if (_selectedPeriodType == 'monthly') {
        _monthlyBudget = budget;
      } else {
        _weeklyBudget = budget;
      }

      debugPrint('[BudgetProvider] ======== SAVE BUDGET SUCCESS ========');
      debugPrint('[BudgetProvider] Budget saved and notifying listeners');
      notifyListeners();
    } catch (e) {
      debugPrint('[BudgetProvider] ======== SAVE BUDGET FAILED ========');
      debugPrint('[BudgetProvider] Error saving budget: $e');
      debugPrint('[BudgetProvider] Error type: ${e.runtimeType}');
      _error = e.toString();
      rethrow;
    }
  }

  /// Update category budget
  Future<void> updateCategoryBudget(
    String uid,
    String categoryId,
    double amount,
  ) async {
    if (_repository == null || currentBudget == null) return;

    try {
      final periodId = currentBudget!.periodId;
      
      debugPrint('[BudgetProvider] Updating category budget for $categoryId = $amount');

      await _repository!.updateCategoryBudget(
        uid,
        _selectedPeriodType,
        periodId,
        categoryId,
        amount,
      );

      // Update in-memory budget
      final updatedBudget = currentBudget!.copyWith(
        categoryBudgets: {
          ...currentBudget!.categoryBudgets,
          categoryId: amount,
        },
      );

      if (_selectedPeriodType == 'monthly') {
        _monthlyBudget = updatedBudget;
      } else {
        _weeklyBudget = updatedBudget;
      }

      debugPrint('[BudgetProvider] Category budget updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('[BudgetProvider] Error updating category budget: $e');
      _error = e.toString();
      rethrow;
    }
  }

  /// Delete budget for current period
  Future<void> deleteBudget(String uid) async {
    if (_repository == null) return;

    try {
      final periodId = currentBudget?.periodId ?? currentPeriodId;
      
      debugPrint('[BudgetProvider] Deleting budget for user=$uid');

      await _repository!.deleteBudget(uid, _selectedPeriodType, periodId);

      if (_selectedPeriodType == 'monthly') {
        _monthlyBudget = null;
      } else {
        _weeklyBudget = null;
      }

      debugPrint('[BudgetProvider] Budget deleted successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('[BudgetProvider] Error deleting budget: $e');
      _error = e.toString();
      rethrow;
    }
  }

  /// Load both monthly and weekly budgets for a user
  /// Useful for switching between them
  Future<void> loadAllBudgets(String uid) async {
    if (_repository == null) return;

    try {
      debugPrint('[BudgetProvider] Loading all budgets for user=$uid');

      final monthlyId = PeriodHelper.getCurrentMonthId();
      final weeklyId = PeriodHelper.getCurrentWeekId();

      final monthlyBudget =
          await _repository!.getBudget(uid, 'monthly', monthlyId);
      final weeklyBudget = await _repository!.getBudget(uid, 'weekly', weeklyId);

      _monthlyBudget = monthlyBudget;
      _weeklyBudget = weeklyBudget;

      debugPrint('[BudgetProvider] All budgets loaded successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('[BudgetProvider] Error loading all budgets: $e');
      _error = e.toString();
    }
  }

  /// Clear budget data
  void clear() {
    debugPrint('[BudgetProvider] Clearing budget data');
    _monthlyBudget = null;
    _weeklyBudget = null;
    _loading = false;
    _error = null;
    _selectedPeriodType = 'monthly';
    notifyListeners();
  }
}
