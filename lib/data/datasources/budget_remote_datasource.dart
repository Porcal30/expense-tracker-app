import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/period_helper.dart';
import '../models/budget.dart';

void _sortBudgetsNewestFirst(List<Budget> list) {
  list.sort(PeriodHelper.compareBudgetsNewestFirst);
}

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

      final docId = PeriodHelper.buildBudgetDocumentId(periodType, periodId);
      debugPrint(
        '[BudgetRemoteDataSource] getBudget uid=$uid periodType=$periodType '
        'periodId=$periodId documentId=$docId',
      );

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(docId)
          .get();

      debugPrint(
        '[BudgetRemoteDataSource] Snapshot for $docId exists=${doc.exists}',
      );

      if (!doc.exists) {
        debugPrint('[BudgetRemoteDataSource] No budget document at $docId');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('[BudgetRemoteDataSource] Budget document $docId has null data');
        return null;
      }

      final budget = Budget.fromJson(Map<String, dynamic>.from(data));
      debugPrint(
        '[BudgetRemoteDataSource] Parsed budget total=${budget.totalBudget} '
        'periodType=${budget.periodType} periodId=${budget.periodId}',
      );
      return budget;
    } catch (e) {
      debugPrint('[BudgetRemoteDataSource] Error loading budget: $e');
      rethrow;
    }
  }

  /// Find the most recent earlier budget of the same period type.
  Future<Budget?> getPreviousBudget(
    String uid,
    String periodType,
    String currentPeriodId,
  ) async {
    if (uid.isEmpty) {
      throw Exception('Cannot get previous budget: uid is empty');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .where('periodType', isEqualTo: periodType)
        .orderBy('periodId', descending: true)
        .get();

    final budgets = snapshot.docs
        .map((doc) => Budget.fromJson(Map<String, dynamic>.from(doc.data())))
        .where(
          (budget) => PeriodHelper.isEarlierPeriod(
            periodType,
            budget.periodId,
            currentPeriodId,
          ),
        )
        .toList();

    if (budgets.isEmpty) {
      debugPrint(
        '[BudgetRemoteDataSource] No previous budget found for uid=$uid periodType=$periodType current=$currentPeriodId',
      );
      return null;
    }

    final previousBudget = budgets.first;
    debugPrint(
      '[BudgetRemoteDataSource] Previous budget found: ${previousBudget.periodId} for uid=$uid periodType=$periodType',
    );
    return previousBudget;
  }

  /// Set/create budget for a specific user
  /// Path: users/{uid}/budgets/{docId}
  /// docId format: {periodType}_{periodId}
  Future<void> setBudget(Budget budget) async {
    try {
      if (budget.userId.isEmpty) {
        throw Exception('Cannot save budget: userId is empty');
      }
      if (budget.periodType.isEmpty) {
        throw Exception('Cannot save budget: periodType is empty');
      }
      if (budget.periodId.isEmpty) {
        throw Exception('Cannot save budget: periodId is empty');
      }

      final docId = PeriodHelper.buildBudgetDocumentId(
        budget.periodType,
        budget.periodId,
      );
      final path = 'users/${budget.userId}/budgets/$docId';
      final jsonData = budget.toJson();

      debugPrint('[BudgetRemoteDataSource] ======== SAVING BUDGET ========');
      debugPrint('[BudgetRemoteDataSource] Path: $path');
      debugPrint('[BudgetRemoteDataSource] UID: ${budget.userId}');
      debugPrint('[BudgetRemoteDataSource] Period Type: ${budget.periodType}');
      debugPrint('[BudgetRemoteDataSource] Period ID: ${budget.periodId}');
      debugPrint(
        '[BudgetRemoteDataSource] Total Budget: ${budget.totalBudget}',
      );
      debugPrint(
        '[BudgetRemoteDataSource] Category Budgets: ${budget.categoryBudgets}',
      );
      debugPrint('[BudgetRemoteDataSource] JSON Data: $jsonData');
      debugPrint('[BudgetRemoteDataSource] ======== START WRITE ========');

      await _firestore
          .collection('users')
          .doc(budget.userId)
          .collection('budgets')
          .doc(docId)
          .set(jsonData, SetOptions(merge: true));

      debugPrint('[BudgetRemoteDataSource] ======== WRITE SUCCESS ========');
      debugPrint(
        '[BudgetRemoteDataSource] Budget saved successfully to: $path',
      );
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

      final docId = PeriodHelper.buildBudgetDocumentId(periodType, periodId);
      debugPrint(
        '[BudgetRemoteDataSource] Updating category budget: uid=$uid, docId=$docId, categoryId=$categoryId, amount=$amount',
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(docId)
          .update({'categoryBudgets.$categoryId': amount});

      debugPrint(
        '[BudgetRemoteDataSource] Category budget updated successfully',
      );
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

      final docId = PeriodHelper.buildBudgetDocumentId(periodType, periodId);
      debugPrint(
        '[BudgetRemoteDataSource] Deleting budget: uid=$uid, docId=$docId',
      );

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

  /// All budget documents for [uid], sorted newest-first.
  Future<List<Budget>> getAllBudgets(String uid) async {
    if (uid.isEmpty) {
      throw Exception('Cannot list budgets: uid is empty');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .get();

    final List<Budget> result = [];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        result.add(Budget.fromJson(Map<String, dynamic>.from(data)));
      } catch (e) {
        debugPrint(
          '[BudgetRemoteDataSource] Skipping invalid budget doc ${doc.id}: $e',
        );
      }
    }

    _sortBudgetsNewestFirst(result);
    return result;
  }
}