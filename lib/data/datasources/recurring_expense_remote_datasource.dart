import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recurring_expense.dart';

class RecurringExpenseRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('recurring_expenses');
  }

  Stream<List<RecurringExpense>> watchRecurringExpenses(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecurringExpense.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<RecurringExpense>> getRecurringExpenses(String uid) async {
    final snapshot =
        await _collection(uid).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => RecurringExpense.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addRecurringExpense(RecurringExpense item) async {
    await _collection(item.userId).doc(item.id).set(item.toMap());
  }

  Future<void> updateRecurringExpense(RecurringExpense item) async {
    await _collection(item.userId).doc(item.id).update(item.toMap());
  }

  Future<void> deleteRecurringExpense(String uid, String recurringId) async {
    await _collection(uid).doc(recurringId).delete();
  }
}
