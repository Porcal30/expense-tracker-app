import 'package:intl/intl.dart';

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
  /// Uses ISO 8601 week numbering (Monday is first day of week)
  static String getWeekId(DateTime date) {
    final year = date.year;
    final weekNumber = _getIsoWeekNumber(date);
    return '$year-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Get ISO week number (1-53) for a given date
  /// ISO 8601: Week 1 is the first week with a Thursday in the new year
  static int _getIsoWeekNumber(DateTime date) {
    // Find the Monday of the week containing Jan 4
    final jan4 = DateTime(date.year, 1, 4);
    final jan4DayOfWeek = jan4.weekday;
    final yearFirstMonday = jan4.subtract(Duration(days: jan4DayOfWeek - 1));
    
    // Calculate week number
    final diff = date.difference(yearFirstMonday).inDays;
    final weekNumber = (diff ~/ 7) + 1;
    
    return weekNumber;
  }

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
          final monthName =
              DateFormat('MMMM').format(DateTime(int.parse(year), month));
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

  /// Get start date of a week given the week ID (yyyy-W##)
  static DateTime getWeekStartDate(String periodId) {
    try {
      final parts = periodId.split('-W');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final week = int.parse(parts[1]);
        
        // ISO 8601: Jan 4 is always in week 1
        final jan4 = DateTime(year, 1, 4);
        final jan4DayOfWeek = jan4.weekday;
        final yearFirstMonday = jan4.subtract(Duration(days: jan4DayOfWeek - 1));
        
        // Calculate Monday of the target week
        final weekStartDate = yearFirstMonday.add(Duration(days: (week - 1) * 7));
        return weekStartDate;
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

  /// Build a unique budget document ID from period type and period ID
  /// Examples:
  /// - monthly_2026-04
  /// - weekly_2026-W15
  static String buildBudgetDocId(String periodType, String periodId) {
    return '${periodType}_$periodId';
  }

  /// Parse a budget document ID to get period type and ID
  /// Returns a map with 'periodType' and 'periodId' keys
  static Map<String, String>? parseBudgetDocId(String docId) {
    final underscoreIndex = docId.indexOf('_');
    if (underscoreIndex > 0 && underscoreIndex < docId.length - 1) {
      final periodType = docId.substring(0, underscoreIndex);
      final periodId = docId.substring(underscoreIndex + 1);
      return {
        'periodType': periodType,
        'periodId': periodId,
      };
    }
    return null;
  }

  /// Check if a period type is valid
  static bool isValidPeriodType(String periodType) {
    return periodType == 'monthly' || periodType == 'weekly';
  }
}
