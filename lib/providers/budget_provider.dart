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

  // Track whether the CURRENT monthly/weekly period has been loaded at least once
  bool _monthlyLoaded = false;
  bool _weeklyLoaded = false;

  bool _isLoading = false;
  String? _error;

  bool _wasAutoCopied = false;
  String? _autoCopiedFromPeriodId;

  List<Budget> _budgetHistory = [];
  bool _isHistoryLoading = false;
  String? _historyError;

  BudgetProvider(this._repository, this._expenseProvider);

  void attachRepositories(
    BudgetRepository budgetRepository,
    ExpenseProvider expenseProvider,
  ) {
    _repository = budgetRepository;
    _expenseProvider = expenseProvider;
    debugPrint('[BudgetProvider] Repositories attached');
  }

  // ============ GETTERS ============

  String get selectedPeriodType => _selectedPeriodType;

  /// True while a Firestore budget fetch is in progress.
  bool get isLoading => _isLoading;

  String? get error => _error;

  List<Budget> get budgetHistory => List.unmodifiable(_budgetHistory);

  bool get isHistoryLoading => _isHistoryLoading;

  String? get historyError => _historyError;

  bool get wasAutoCopied => _wasAutoCopied;

  String? get autoCopiedFromPeriodId => _autoCopiedFromPeriodId;

  /// Current budget based on selected period type
  Budget? get currentBudget {
    return _selectedPeriodType == 'monthly' ? _monthlyBudget : _weeklyBudget;
  }

  bool get hasBudget => currentBudget != null;

  /// True only after the current selected period has actually finished loading.
  bool get hasLoadedCurrentPeriod {
    return _selectedPeriodType == 'monthly' ? _monthlyLoaded : _weeklyLoaded;
  }

  /// Get current period ID based on selected type
  String get currentPeriodId {
    if (_selectedPeriodType == 'monthly') {
      return PeriodHelper.currentMonthPeriodId();
    } else {
      return PeriodHelper.currentWeekPeriodId();
    }
  }

  /// Get human-readable label for current period
  String get currentPeriodLabel =>
      PeriodHelper.getPeriodLabel(_selectedPeriodType, currentPeriodId);

  /// Friendly UI label
  String get currentPeriodDisplayLabel =>
      PeriodHelper.getFriendlyPeriodLabel(_selectedPeriodType);

  String get currentBudgetTitle => currentPeriodDisplayLabel;

  /// Total budget amount for current period
  double get totalBudget => currentBudget?.totalBudget ?? 0.0;

  /// Total spent in current period
  double get totalSpent {
    if (_expenseProvider == null) return 0.0;

    return _expenseProvider!.expenses
        .where(
          (expense) => PeriodHelper.belongsToPeriod(
            expense.date,
            _selectedPeriodType,
            currentPeriodId,
          ),
        )
        .fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Remaining budget
  double get remainingBudget =>
      (totalBudget - totalSpent).clamp(0.0, double.infinity);

  /// Clamped percentage for progress bars
  double get budgetPercentage {
    if (totalBudget == 0.0) return 0.0;
    return (totalSpent / totalBudget).clamp(0.0, 1.0);
  }

  bool get isOverBudget => totalSpent > totalBudget;

  // ============ CATEGORY METHODS ============

  double getCategoryBudget(String categoryId) {
    return currentBudget?.categoryBudgets[categoryId] ?? 0.0;
  }

  double getCategorySpent(String categoryId) {
    if (_expenseProvider == null) return 0.0;

    return _expenseProvider!.expenses
        .where(
          (expense) =>
              expense.categoryId == categoryId &&
              PeriodHelper.belongsToPeriod(
                expense.date,
                _selectedPeriodType,
                currentPeriodId,
              ),
        )
        .fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  double getCategoryPercentage(String categoryId) {
    final budget = getCategoryBudget(categoryId);
    if (budget == 0.0) return 0.0;
    final spent = getCategorySpent(categoryId);
    return (spent / budget).clamp(0.0, 1.0);
  }

  bool isCategoryBudgetExceeded(String categoryId) {
    return getCategorySpent(categoryId) > getCategoryBudget(categoryId);
  }

  /// Total expense amount in [budget]'s period (for history and analytics).
  double getTotalSpentForBudget(Budget budget) {
    if (_expenseProvider == null) return 0.0;

    return _expenseProvider!.expenses
        .where(
          (expense) => PeriodHelper.belongsToPeriod(
            expense.date,
            budget.periodType,
            budget.periodId,
          ),
        )
        .fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Remaining amount for [budget] (negative when over budget).
  double getRemainingForBudget(Budget budget) {
    return budget.totalBudget - getTotalSpentForBudget(budget);
  }

  bool isOverBudgetFor(Budget budget) {
    return getTotalSpentForBudget(budget) > budget.totalBudget;
  }

  Future<void> loadBudgetHistory(String uid) async {
    if (_repository == null) {
      debugPrint(
        '[BudgetProvider] loadBudgetHistory skipped: repository not attached',
      );
      return;
    }

    if (uid.isEmpty) {
      _historyError = 'Cannot load budget history: uid is empty';
      notifyListeners();
      return;
    }

    _isHistoryLoading = true;
    _historyError = null;
    notifyListeners();

    try {
      _budgetHistory = await _repository!.getAllBudgets(uid);
      debugPrint(
        '[BudgetProvider] loadBudgetHistory loaded ${_budgetHistory.length} budgets',
      );
    } catch (e) {
      debugPrint('[BudgetProvider] loadBudgetHistory error: $e');
      _historyError = e.toString();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  // ============ LOAD/SAVE METHODS ============

  Future<void> setPeriodType(String periodType, String uid) async {
    if (!PeriodHelper.isValidPeriodType(periodType)) {
      throw Exception('Invalid period type: $periodType');
    }

    if (_selectedPeriodType == periodType) return;

    _selectedPeriodType = periodType;
    notifyListeners();

    await loadCurrentBudget(uid);
  }

  Future<void> loadBudget(String uid) async {
    await loadCurrentBudget(uid);
  }

  Future<void> loadCurrentBudget(String uid) async {
    if (_repository == null) {
      debugPrint(
        '[BudgetProvider] loadCurrentBudget skipped: repository not attached yet',
      );
      return;
    }

    if (uid.isEmpty) {
      _error = 'Cannot load budget: uid is empty';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final periodId = currentPeriodId;
      final documentId = PeriodHelper.buildBudgetDocumentId(
        _selectedPeriodType,
        periodId,
      );

      debugPrint('[BudgetProvider] ======== LOAD CURRENT BUDGET ========');
      debugPrint('[BudgetProvider] uid=$uid');
      debugPrint('[BudgetProvider] selectedPeriodType=$_selectedPeriodType');
      debugPrint('[BudgetProvider] periodId=$periodId');
      debugPrint('[BudgetProvider] documentId=$documentId');

      final budget = await _repository!.getBudget(
        uid,
        _selectedPeriodType,
        periodId,
      );

      if (_selectedPeriodType == 'monthly') {
        _monthlyBudget = budget;
        _monthlyLoaded = true;
      } else {
        _weeklyBudget = budget;
        _weeklyLoaded = true;
      }

      _wasAutoCopied = false;
      _autoCopiedFromPeriodId = null;

      if (budget != null) {
        debugPrint(
          '[BudgetProvider] Document exists; loaded totalBudget=${budget.totalBudget}',
        );
      } else {
        debugPrint(
          '[BudgetProvider] No document found for $documentId (empty state is valid)',
        );
        final copiedBudget = await _copyPreviousBudgetIfMissing(
          uid,
          _selectedPeriodType,
          periodId,
        );

        if (copiedBudget != null) {
          _wasAutoCopied = true;
          if (_selectedPeriodType == 'monthly') {
            _monthlyBudget = copiedBudget;
            _monthlyLoaded = true;
          } else {
            _weeklyBudget = copiedBudget;
            _weeklyLoaded = true;
          }
        }
      }
    } catch (e) {
      debugPrint('[BudgetProvider] Error loading budget: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Budget?> _copyPreviousBudgetIfMissing(
    String uid,
    String periodType,
    String periodId,
  ) async {
    if (_repository == null) return null;

    final existingBudget = await _repository!.getBudget(
      uid,
      periodType,
      periodId,
    );
    if (existingBudget != null) {
      return null;
    }

    final previousBudget = await _repository!.getPreviousBudget(
      uid,
      periodType,
      periodId,
    );
    if (previousBudget == null) {
      return null;
    }

    final newBudget = previousBudget.copyWith(
      userId: uid,
      periodType: periodType,
      periodId: periodId,
    );

    await _repository!.setBudget(newBudget);
    _autoCopiedFromPeriodId = previousBudget.periodId;
    debugPrint(
      '[BudgetProvider] Auto-copied previous budget from ${previousBudget.periodId} '
      'into current period $periodId',
    );
    return newBudget;
  }

  Future<void> saveBudget(
    String uid,
    double totalBudget,
    Map<String, double> categoryBudgets,
  ) async {
    if (_repository == null) return;

    try {
      if (uid.isEmpty) {
        throw Exception('Cannot save budget: uid is empty or null');
      }
      if (!PeriodHelper.isValidPeriodType(_selectedPeriodType)) {
        throw Exception(
          'Cannot save budget: invalid periodType $_selectedPeriodType',
        );
      }

      final periodId = currentPeriodId;
      final documentId = PeriodHelper.buildBudgetDocumentId(
        _selectedPeriodType,
        periodId,
      );

      debugPrint('[BudgetProvider] ======== SAVE BUDGET REQUEST ========');
      debugPrint('[BudgetProvider] UID: $uid');
      debugPrint('[BudgetProvider] Period Type: $_selectedPeriodType');
      debugPrint('[BudgetProvider] Period ID: $periodId');
      debugPrint('[BudgetProvider] documentId=$documentId');
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

      await _repository!.setBudget(budget);

      if (_selectedPeriodType == 'monthly') {
        _monthlyBudget = budget;
        _monthlyLoaded = true;
      } else {
        _weeklyBudget = budget;
        _weeklyLoaded = true;
      }

      debugPrint('[BudgetProvider] ======== SAVE BUDGET SUCCESS ========');
      notifyListeners();
    } catch (e) {
      debugPrint('[BudgetProvider] ======== SAVE BUDGET FAILED ========');
      debugPrint('[BudgetProvider] Error saving budget: $e');
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> updateCategoryBudget(
    String uid,
    String categoryId,
    double amount,
  ) async {
    if (_repository == null || currentBudget == null) return;

    try {
      final periodId = currentBudget!.periodId;

      debugPrint(
        '[BudgetProvider] Updating category budget for $categoryId = $amount',
      );

      await _repository!.updateCategoryBudget(
        uid,
        _selectedPeriodType,
        periodId,
        categoryId,
        amount,
      );

      final updatedBudget = currentBudget!.copyWith(
        categoryBudgets: {
          ...currentBudget!.categoryBudgets,
          categoryId: amount,
        },
      );

      if (_selectedPeriodType == 'monthly') {
        _monthlyBudget = updatedBudget;
        _monthlyLoaded = true;
      } else {
        _weeklyBudget = updatedBudget;
        _weeklyLoaded = true;
      }

      debugPrint('[BudgetProvider] Category budget updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('[BudgetProvider] Error updating category budget: $e');
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteBudget(String uid) async {
    if (_repository == null) return;

    try {
      final periodId = currentBudget?.periodId ?? currentPeriodId;

      debugPrint('[BudgetProvider] Deleting budget for user=$uid');

      await _repository!.deleteBudget(uid, _selectedPeriodType, periodId);

      if (_selectedPeriodType == 'monthly') {
        _monthlyBudget = null;
        _monthlyLoaded = true;
      } else {
        _weeklyBudget = null;
        _weeklyLoaded = true;
      }

      debugPrint('[BudgetProvider] Budget deleted successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('[BudgetProvider] Error deleting budget: $e');
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> loadAllBudgets(String uid) async {
    if (_repository == null) {
      debugPrint(
        '[BudgetProvider] loadAllBudgets skipped: repository not attached yet',
      );
      return;
    }

    if (uid.isEmpty) {
      _error = 'Cannot load budgets: uid is empty';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final monthlyId = PeriodHelper.currentMonthPeriodId();
      final weeklyId = PeriodHelper.currentWeekPeriodId();
      final monthlyDocId = PeriodHelper.buildBudgetDocumentId(
        'monthly',
        monthlyId,
      );
      final weeklyDocId = PeriodHelper.buildBudgetDocumentId(
        'weekly',
        weeklyId,
      );

      debugPrint('[BudgetProvider] ======== LOAD ALL BUDGETS ========');
      debugPrint('[BudgetProvider] uid=$uid');
      debugPrint('[BudgetProvider] selectedPeriodType=$_selectedPeriodType');
      debugPrint(
        '[BudgetProvider] monthly periodId=$monthlyId doc=$monthlyDocId',
      );
      debugPrint('[BudgetProvider] weekly periodId=$weeklyId doc=$weeklyDocId');

      final monthlyBudget = await _repository!.getBudget(
        uid,
        'monthly',
        monthlyId,
      );
      final weeklyBudget = await _repository!.getBudget(
        uid,
        'weekly',
        weeklyId,
      );

      _monthlyBudget = monthlyBudget;
      _weeklyBudget = weeklyBudget;
      _monthlyLoaded = true;
      _weeklyLoaded = true;

      debugPrint(
        '[BudgetProvider] monthly exists=${monthlyBudget != null}, weekly exists=${weeklyBudget != null}',
      );
    } catch (e) {
      debugPrint('[BudgetProvider] Error loading all budgets: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    debugPrint('[BudgetProvider] Clearing budget data');
    _monthlyBudget = null;
    _weeklyBudget = null;
    _monthlyLoaded = false;
    _weeklyLoaded = false;
    _isLoading = false;
    _error = null;
    _budgetHistory = [];
    _isHistoryLoading = false;
    _historyError = null;
    _selectedPeriodType = 'monthly';
    notifyListeners();
  }
}
