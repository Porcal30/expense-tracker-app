import '../datasources/recurring_expense_remote_datasource.dart';
import '../models/recurring_expense.dart';

class RecurringExpenseRepository {
  final RecurringExpenseRemoteDataSource _remote;

  RecurringExpenseRepository(this._remote);

  Stream<List<RecurringExpense>> watchRecurringExpenses(String uid) =>
      _remote.watchRecurringExpenses(uid);

  Future<List<RecurringExpense>> getRecurringExpenses(String uid) =>
      _remote.getRecurringExpenses(uid);

  Future<void> addRecurringExpense(RecurringExpense item) =>
      _remote.addRecurringExpense(item);

  Future<void> updateRecurringExpense(RecurringExpense item) =>
      _remote.updateRecurringExpense(item);

  Future<void> deleteRecurringExpense(String uid, String recurringId) =>
      _remote.deleteRecurringExpense(uid, recurringId);
}
