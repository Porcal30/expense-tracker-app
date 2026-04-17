import 'package:flutter/foundation.dart';

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
      debugPrint('[BudgetRepository] uid=$uid, periodType=$periodType, periodId=$periodId');
      
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
      debugPrint('[BudgetRepository] Path will be: users/${budget.userId}/budgets/${budget.periodType}_${budget.periodId}');
      
      await _dataSource.setBudget(budget);
      
      debugPrint('[BudgetRepository] ======== SET BUDGET SUCCESS ========');
    } catch (e) {
      debugPrint('[BudgetRepository] ======== SET BUDGET FAILED ========');
      debugPrint('[BudgetRepository] Error setting budget: $e');
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
      await _dataSource.updateCategoryBudget(uid, periodType, periodId, categoryId, amount);
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
      debugPrint('[BudgetRepository] Deleting budget: uid=$uid, periodType=$periodType, periodId=$periodId');
      await _dataSource.deleteBudget(uid, periodType, periodId);
    } catch (e) {
      debugPrint('[BudgetRepository] Error deleting budget: $e');
      rethrow;
    }
  }
}
