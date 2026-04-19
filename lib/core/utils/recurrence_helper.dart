import '../../data/models/recurring_expense.dart';

/// Date-only recurrence checks for recurring expense templates (v1).
abstract final class RecurrenceHelper {
  /// Normalizes [dt] to local calendar date at midnight.
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Whether [template] should generate an expense as of [now].
  ///
  /// Rules:
  /// - **daily**: startDate ≤ today and lastGeneratedDate is before today (or absent).
  /// - **weekly**: startDate ≤ today and at least 7 days since lastGeneratedDate (or absent).
  /// - **monthly**: startDate ≤ today and nothing generated yet this calendar month.
  ///
  /// Caller should still verify [template.isActive].
  static bool isDue(RecurringExpense template, DateTime now) {
    final today = dateOnly(now);
    final start = dateOnly(template.startDate);
    if (start.isAfter(today)) return false;

    final last = template.lastGeneratedDate != null
        ? dateOnly(template.lastGeneratedDate!)
        : null;

    switch (template.frequency) {
      case 'daily':
        if (last == null) return true;
        return last.isBefore(today);
      case 'weekly':
        if (last == null) return true;
        return today.difference(last).inDays >= 7;
      case 'monthly':
        if (last == null) return true;
        return !(last.year == today.year && last.month == today.month);
      default:
        return false;
    }
  }
}
