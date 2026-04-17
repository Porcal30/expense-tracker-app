import '../datasources/expense_remote_datasource.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final ExpenseRemoteDataSource _remote;

  ExpenseRepository(this._remote);

  Stream<List<Expense>> watchExpenses(String uid) => _remote.watchExpenses(uid);
  Future<void> addExpense(Expense expense) => _remote.addExpense(expense);
  Future<void> updateExpense(Expense expense) => _remote.updateExpense(expense);
  Future<void> deleteExpense(String uid, String expenseId) =>
      _remote.deleteExpense(uid, expenseId);
}