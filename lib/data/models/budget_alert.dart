enum BudgetAlertSeverity { info, warning, danger }

class BudgetAlert {
  final String message;
  final BudgetAlertSeverity severity;
  final double percentUsed;
  final bool isOverBudget;
  final double? overAmount;

  const BudgetAlert({
    required this.message,
    required this.severity,
    required this.percentUsed,
    required this.isOverBudget,
    this.overAmount,
  });
}

class CategoryBudgetAlert {
  final String categoryId;
  final String message;
  final BudgetAlertSeverity severity;
  final double percentUsed;
  final double? overAmount;

  const CategoryBudgetAlert({
    required this.categoryId,
    required this.message,
    required this.severity,
    required this.percentUsed,
    this.overAmount,
  });
}
