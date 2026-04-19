import 'package:flutter/foundation.dart';

import '../../core/utils/period_helper.dart';
import '../datasources/budget_remote_datasource.dart';
import '../models/budget.dart';

class BudgetRepository {
  final BudgetRemoteDataSource _dataSource;

  BudgetRepository(this._dataSource);

  /// Get budget for a specific user, period type, and period ID
  Future<Budget?> getBudget(
    String uid,
    String periodType,
    String periodId,
  ) async {
    try {
      debugPrint('[BudgetRepository] ======== GET BUDGET ========');
      final documentId = PeriodHelper.buildBudgetDocumentId(
        periodType,
        periodId,
      );
      debugPrint(
        '[BudgetRepository] getBudget uid=$uid periodType=$periodType '
        'periodId=$periodId documentId=$documentId',
      );

      final budget = await _dataSource.getBudget(uid, periodType, periodId);

      debugPrint('[BudgetRepository] ======== GET BUDGET SUCCESS ========');
      return budget;
    } catch (e) {
      debugPrint('[BudgetRepository] ======== GET BUDGET FAILED ========');
      debugPrint('[BudgetRepository] Error getting budget: $e');
      rethrow;
    }
  }

  /// Save budget for a specific user
  Future<void> setBudget(Budget budget) async {
    try {
      debugPrint('[BudgetRepository] ======== SET BUDGET ========');
      debugPrint('[BudgetRepository] Budget: $budget');
      debugPrint(
        '[BudgetRepository] Path will be: users/${budget.userId}/budgets/'
        '${PeriodHelper.buildBudgetDocumentId(budget.periodType, budget.periodId)}',
      );

      await _dataSource.setBudget(budget);

      debugPrint('[BudgetRepository] ======== SET BUDGET SUCCESS ========');
    } catch (e) {
      debugPrint('[BudgetRepository] ======== SET BUDGET FAILED ========');
      debugPrint('[BudgetRepository] Error setting budget: $e');
      rethrow;
    }
  }

  /// Get the most recent previous budget for the same type.
  Future<Budget?> getPreviousBudget(
    String uid,
    String periodType,
    String currentPeriodId,
  ) async {
    try {
      final previousBudget = await _dataSource.getPreviousBudget(
        uid,
        periodType,
        currentPeriodId,
      );
      return previousBudget;
    } catch (e) {
      debugPrint('[BudgetRepository] Error getting previous budget: $e');
      rethrow;
    }
  }

  /// Update category budget
  Future<void> updateCategoryBudget(
    String uid,
    String periodType,
    String periodId,
    String categoryId,
    double amount,
  ) async {
    try {
      debugPrint('[BudgetRepository] Updating category budget');
      await _dataSource.updateCategoryBudget(
        uid,
        periodType,
        periodId,
        categoryId,
        amount,
      );
    } catch (e) {
      debugPrint('[BudgetRepository] Error updating category budget: $e');
      rethrow;
    }
  }

  /// Delete budget
  Future<void> deleteBudget(
    String uid,
    String periodType,
    String periodId,
  ) async {
    try {
      debugPrint(
        '[BudgetRepository] Deleting budget: uid=$uid, periodType=$periodType, periodId=$periodId',
      );
      await _dataSource.deleteBudget(uid, periodType, periodId);
    } catch (e) {
      debugPrint('[BudgetRepository] Error deleting budget: $e');
      rethrow;
    }
  }

  /// All budgets for the user (newest periods first).
  Future<List<Budget>> getAllBudgets(String uid) =>
      _dataSource.getAllBudgets(uid);
}
