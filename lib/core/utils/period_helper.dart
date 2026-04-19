import 'package:intl/intl.dart';

import '../../data/models/budget.dart';

/// Helper utilities for managing monthly and weekly budget periods
class PeriodHelper {
  /// Get current month ID in format: yyyy-MM
  /// Example: 2026-04
  static String getCurrentMonthId() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM').format(now);
  }

  /// Get month ID for a specific date in format: yyyy-MM
  static String getMonthId(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  /// Get current week ID in format: yyyy-W##
  /// Example: 2026-W15
  static String getCurrentWeekId() {
    return getWeekId(DateTime.now());
  }

  /// Get week ID for a specific date in format: yyyy-W##
  /// Uses ISO 8601 week date (Monday week start; week 1 contains Jan 4).
  static String getWeekId(DateTime date) {
    final monday = _mondayOfCalendarWeek(date);
    final thursday = monday.add(const Duration(days: 3));
    var isoYear = thursday.year;
    var week1Monday = _mondayOfIsoWeek1(isoYear);

    if (monday.isBefore(week1Monday)) {
      isoYear--;
      week1Monday = _mondayOfIsoWeek1(isoYear);
    } else {
      final nextWeek1Monday = _mondayOfIsoWeek1(isoYear + 1);
      if (!monday.isBefore(nextWeek1Monday)) {
        isoYear++;
        week1Monday = _mondayOfIsoWeek1(isoYear);
      }
    }

    final weekNumber = 1 + monday.difference(week1Monday).inDays ~/ 7;
    return '$isoYear-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Calendar Monday of the week containing [date] (`DateTime.weekday`: Mon = 1).
  static DateTime _mondayOfCalendarWeek(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  /// Monday of ISO week 1 for [isoYear] (Monday of the week that contains Jan 4).
  static DateTime _mondayOfIsoWeek1(int isoYear) {
    return _mondayOfCalendarWeek(DateTime(isoYear, 1, 4));
  }

  /// Current month period id (`yyyy-MM`). Same as [getCurrentMonthId].
  static String currentMonthPeriodId() => getCurrentMonthId();

  /// Current ISO week period id (`yyyy-W##`). Same as [getCurrentWeekId].
  static String currentWeekPeriodId() => getCurrentWeekId();

  /// Check if a date belongs to the given monthly period
  /// period format: yyyy-MM
  static bool belongsToMonthlyPeriod(DateTime date, String monthPeriod) {
    return getMonthId(date) == monthPeriod;
  }

  /// Check if a date belongs to the given weekly period
  /// period format: yyyy-W##
  static bool belongsToWeeklyPeriod(DateTime date, String weekPeriod) {
    return getWeekId(date) == weekPeriod;
  }

  /// Check if a date belongs to the given period
  static bool belongsToPeriod(
    DateTime date,
    String periodType,
    String periodId,
  ) {
    if (periodType == 'monthly') {
      return belongsToMonthlyPeriod(date, periodId);
    } else if (periodType == 'weekly') {
      return belongsToWeeklyPeriod(date, periodId);
    }
    return false;
  }

  /// Get a human-readable label for a period
  /// Examples:
  /// - 'April 2026' for monthly
  /// - 'Week 15, 2026' for weekly
  static String getPeriodLabel(String periodType, String periodId) {
    if (periodType == 'monthly') {
      try {
        final parts = periodId.split('-');
        if (parts.length == 2) {
          final year = parts[0];
          final month = int.parse(parts[1]);
          final monthName = DateFormat(
            'MMMM',
          ).format(DateTime(int.parse(year), month));
          return '$monthName $year';
        }
      } catch (_) {}
      return periodId;
    } else if (periodType == 'weekly') {
      try {
        final parts = periodId.split('-W');
        if (parts.length == 2) {
          final year = parts[0];
          final week = parts[1];
          return 'Week $week, $year';
        }
      } catch (_) {}
      return periodId;
    }
    return periodId;
  }

  /// Start date (Monday) of the ISO week given by [periodId] (`yyyy-W##`).
  static DateTime getWeekStartDate(String periodId) {
    try {
      final parts = periodId.split('-W');
      if (parts.length == 2) {
        final isoYear = int.parse(parts[0]);
        final week = int.parse(parts[1]);
        final week1Monday = _mondayOfIsoWeek1(isoYear);
        return week1Monday.add(Duration(days: (week - 1) * 7));
      }
    } catch (_) {}
    return DateTime.now();
  }

  /// Get end date of a week given the week ID (yyyy-W##)
  static DateTime getWeekEndDate(String periodId) {
    final startDate = getWeekStartDate(periodId);
    return startDate.add(const Duration(days: 6)); // Sunday of that week
  }

  /// Get friendly label for current weekly period
  /// Example: "This Week (Apr 14 – Apr 20)"
  static String getFriendlyWeeklyLabel() {
    return getFriendlyWeeklyLabelForDate(DateTime.now());
  }

  /// Get friendly label for weekly period of a given date
  /// Example: "This Week (Apr 14 – Apr 20)"
  static String getFriendlyWeeklyLabelForDate(DateTime date) {
    final weekId = getWeekId(date);
    final startDate = getWeekStartDate(weekId);
    final endDate = getWeekEndDate(weekId);

    final startFormatted = DateFormat('MMM d').format(startDate);
    final endFormatted = DateFormat('MMM d').format(endDate);

    return 'This Week ($startFormatted – $endFormatted)';
  }

  /// Get friendly label for current monthly period
  /// Example: "This Month (April 2026)"
  static String getFriendlyMonthlyLabel() {
    return getFriendlyMonthlyLabelForDate(DateTime.now());
  }

  /// Get friendly label for monthly period of a given date
  /// Example: "This Month (April 2026)"
  static String getFriendlyMonthlyLabelForDate(DateTime date) {
    final monthName = DateFormat('MMMM').format(date);
    final year = date.year;
    return 'This Month ($monthName $year)';
  }

  /// Get friendly display label for current period
  /// Example:
  /// - "This Week (Apr 14 – Apr 20)" for weekly
  /// - "This Month (April 2026)" for monthly
  static String getFriendlyPeriodLabel(String periodType) {
    if (periodType == 'weekly') {
      return getFriendlyWeeklyLabel();
    } else if (periodType == 'monthly') {
      return getFriendlyMonthlyLabel();
    }
    return 'Current Period';
  }

  /// Build a unique Firestore budget document id from period type and period id.
  ///
  /// Examples: `monthly_2026-04`, `weekly_2026-W16`
  /// Use this everywhere reads/writes `users/{uid}/budgets/{docId}`.
  static String buildBudgetDocumentId(String periodType, String periodId) {
    return '${periodType}_$periodId';
  }

  /// Alias for [buildBudgetDocumentId] (legacy name).
  static String buildBudgetDocId(String periodType, String periodId) =>
      buildBudgetDocumentId(periodType, periodId);

  /// Convert a period id into a sort anchor date for comparisons.
  static DateTime periodSortAnchor(String periodType, String periodId) {
    if (periodType == 'weekly') {
      return getWeekEndDate(periodId);
    }

    try {
      final parts = periodId.split('-');
      if (parts.length == 2) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return DateTime(y, m + 1, 0);
      }
    } catch (_) {}

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Compare two period ids for the same period type.
  /// Returns a negative value if [a] is older than [b].
  static int comparePeriodIds(String periodType, String a, String b) {
    return periodSortAnchor(
      periodType,
      a,
    ).compareTo(periodSortAnchor(periodType, b));
  }

  /// True when [first] is strictly earlier than [second] for the same period type.
  static bool isEarlierPeriod(String periodType, String first, String second) {
    return comparePeriodIds(periodType, first, second) < 0;
  }

  /// Parse a budget document ID to get period type and ID
  /// Returns a map with 'periodType' and 'periodId' keys
  static Map<String, String>? parseBudgetDocId(String docId) {
    final underscoreIndex = docId.indexOf('_');
    if (underscoreIndex > 0 && underscoreIndex < docId.length - 1) {
      final periodType = docId.substring(0, underscoreIndex);
      final periodId = docId.substring(underscoreIndex + 1);
      return {'periodType': periodType, 'periodId': periodId};
    }
    return null;
  }

  /// Check if a period type is valid
  static bool isValidPeriodType(String periodType) {
    return periodType == 'monthly' || periodType == 'weekly';
  }

  /// End instant used to sort budgets with most recent periods first.
  /// Monthly uses last calendar day of the month; weekly uses Sunday of that ISO week.
  static DateTime budgetPeriodSortAnchor(Budget budget) {
    if (budget.periodType == 'weekly') {
      return getWeekEndDate(budget.periodId);
    }
    try {
      final parts = budget.periodId.split('-');
      if (parts.length == 2) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return DateTime(y, m + 1, 0);
      }
    } catch (_) {}
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Compare two budgets for descending chronological order (newest first).
  static int compareBudgetsNewestFirst(Budget a, Budget b) {
    final cmp = budgetPeriodSortAnchor(b).compareTo(budgetPeriodSortAnchor(a));
    if (cmp != 0) return cmp;
    if (a.periodType != b.periodType) {
      return a.periodType.compareTo(b.periodType);
    }
    return b.periodId.compareTo(a.periodId);
  }

  /// Short monthly label for history UI, e.g. `April 2026`.
  static String monthlyHistoryLabel(String periodId) {
    try {
      final parts = periodId.split('-');
      if (parts.length == 2) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return DateFormat('MMMM y').format(DateTime(y, m));
      }
    } catch (_) {}
    return periodId;
  }

  /// Short weekly range for history UI, e.g. `Apr 14 – Apr 20` (year implied by context).
  static String weeklyHistoryRangeLabel(String periodId) {
    try {
      final start = getWeekStartDate(periodId);
      final end = getWeekEndDate(periodId);
      final a = DateFormat('MMM d').format(start);
      final b = DateFormat('MMM d').format(end);
      return '$a – $b';
    } catch (_) {
      return periodId;
    }
  }

  /// Friendly label for a stored [Budget] on history screens.
  static String friendlyBudgetHistoryLabel(Budget budget) {
    if (budget.periodType == 'monthly') {
      return monthlyHistoryLabel(budget.periodId);
    }
    if (budget.periodType == 'weekly') {
      return weeklyHistoryRangeLabel(budget.periodId);
    }
    return budget.periodId;
  }
}
