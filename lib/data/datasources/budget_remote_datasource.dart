import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/period_helper.dart';
import '../models/budget.dart';

class BudgetRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get budget for a specific user, period type, and period ID
  /// Path: users/{uid}/budgets/{docId}
  /// docId format: {periodType}_{periodId} (e.g., monthly_2026-04, weekly_2026-W15)
  Future<Budget?> getBudget(
    String uid,
    String periodType,
    String periodId,
  ) async {
    try {
      if (uid.isEmpty) {
        throw Exception('Cannot get budget: uid is empty');
      }

      final docId = PeriodHelper.buildBudgetDocId(periodType, periodId);
      debugPrint('[BudgetRemoteDataSource] Loading budget for user=$uid, docId=$docId');

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(docId)
          .get();

      if (!doc.exists) {
        debugPrint('[BudgetRemoteDataSource] No budget found for $docId');
        return null;
      }

      final budget = Budget.fromJson(doc.data() as Map<String, dynamic>);
      debugPrint('[BudgetRemoteDataSource] Budget loaded: $budget');
      return budget;
    } catch (e) {
      debugPrint('[BudgetRemoteDataSource] Error loading budget: $e');
      rethrow;
    }
  }

  /// Set/create budget for a specific user
  /// Path: users/{uid}/budgets/{docId}
  /// docId format: {periodType}_{periodId}
  Future<void> setBudget(Budget budget) async {
    try {
      // Validate before write
      if (budget.userId.isEmpty) {
        throw Exception('Cannot save budget: userId is empty');
      }
      if (budget.periodType.isEmpty) {
        throw Exception('Cannot save budget: periodType is empty');
      }
      if (budget.periodId.isEmpty) {
        throw Exception('Cannot save budget: periodId is empty');
      }

      final docId = PeriodHelper.buildBudgetDocId(budget.periodType, budget.periodId);
      final path = 'users/${budget.userId}/budgets/$docId';
      final jsonData = budget.toJson();

      debugPrint('[BudgetRemoteDataSource] ======== SAVING BUDGET ========');
      debugPrint('[BudgetRemoteDataSource] Path: $path');
      debugPrint('[BudgetRemoteDataSource] UID: ${budget.userId}');
      debugPrint('[BudgetRemoteDataSource] Period Type: ${budget.periodType}');
      debugPrint('[BudgetRemoteDataSource] Period ID: ${budget.periodId}');
      debugPrint('[BudgetRemoteDataSource] Total Budget: ${budget.totalBudget}');
      debugPrint('[BudgetRemoteDataSource] Category Budgets: ${budget.categoryBudgets}');
      debugPrint('[BudgetRemoteDataSource] JSON Data: $jsonData');
      debugPrint('[BudgetRemoteDataSource] ======== START WRITE ========');

      await _firestore
          .collection('users')
          .doc(budget.userId)
          .collection('budgets')
          .doc(docId)
          .set(jsonData, SetOptions(merge: true));

      debugPrint('[BudgetRemoteDataSource] ======== WRITE SUCCESS ========');
      debugPrint('[BudgetRemoteDataSource] Budget saved successfully to: $path');
    } catch (e) {
      debugPrint('[BudgetRemoteDataSource] ======== WRITE FAILED ========');
      debugPrint('[BudgetRemoteDataSource] Error saving budget: $e');
      debugPrint('[BudgetRemoteDataSource] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Update category budget for a specific user, period type, and period ID
  Future<void> updateCategoryBudget(
    String uid,
    String periodType,
    String periodId,
    String categoryId,
    double amount,
  ) async {
    try {
      if (uid.isEmpty) {
        throw Exception('Cannot update category budget: uid is empty');
      }

      final docId = PeriodHelper.buildBudgetDocId(periodType, periodId);
      debugPrint('[BudgetRemoteDataSource] Updating category budget: uid=$uid, docId=$docId, categoryId=$categoryId, amount=$amount');

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(docId)
          .update({
        'categoryBudgets.$categoryId': amount,
      });

      debugPrint('[BudgetRemoteDataSource] Category budget updated successfully');
    } catch (e) {
      debugPrint('[BudgetRemoteDataSource] Error updating category budget: $e');
      rethrow;
    }
  }

  /// Delete budget for a specific user, period type, and period ID
  Future<void> deleteBudget(
    String uid,
    String periodType,
    String periodId,
  ) async {
    try {
      if (uid.isEmpty) {
        throw Exception('Cannot delete budget: uid is empty');
      }

      final docId = PeriodHelper.buildBudgetDocId(periodType, periodId);
      debugPrint('[BudgetRemoteDataSource] Deleting budget: uid=$uid, docId=$docId');

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(docId)
          .delete();

      debugPrint('[BudgetRemoteDataSource] Budget deleted successfully');
    } catch (e) {
      debugPrint('[BudgetRemoteDataSource] Error deleting budget: $e');
      rethrow;
    }
  }
}
