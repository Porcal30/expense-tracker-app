import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class ExpenseRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('expenses');
  }

  Stream<List<Expense>> watchExpenses(String uid) {
    return _collection(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addExpense(Expense expense) async {
    await _collection(expense.userId).doc(expense.id).set(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _collection(expense.userId).doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String uid, String expenseId) async {
    await _collection(uid).doc(expenseId).delete();
  }
}