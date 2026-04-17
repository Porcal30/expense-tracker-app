class Budget {
  final String userId;
  final String periodType; // 'monthly' or 'weekly'
  final String periodId; // 'yyyy-MM' for monthly, 'yyyy-W##' for weekly
  final double totalBudget;
  final Map<String, double> categoryBudgets;

  Budget({
    required this.userId,
    required this.periodType,
    required this.periodId,
    required this.totalBudget,
    required this.categoryBudgets,
  });

  /// Create Budget from Firestore JSON
  /// Supports backward compatibility with old 'month' field
  factory Budget.fromJson(Map<String, dynamic> json) {
    // Try new format first
    String periodType = json['periodType'] as String? ?? 'monthly';
    String periodId = json['periodId'] as String? ?? (json['month'] as String? ?? '');
    
    return Budget(
      userId: json['userId'] as String? ?? '',
      periodType: periodType,
      periodId: periodId,
      totalBudget: (json['totalBudget'] as num?)?.toDouble() ?? 0.0,
      categoryBudgets: Map<String, double>.from(
        (json['categoryBudgets'] as Map?)?.map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ) ?? {},
      ),
    );
  }

  /// Convert Budget to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'periodType': periodType,
      'periodId': periodId,
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets,
    };
  }

  /// Create a copy with modified fields
  Budget copyWith({
    String? userId,
    String? periodType,
    String? periodId,
    double? totalBudget,
    Map<String, double>? categoryBudgets,
  }) {
    return Budget(
      userId: userId ?? this.userId,
      periodType: periodType ?? this.periodType,
      periodId: periodId ?? this.periodId,
      totalBudget: totalBudget ?? this.totalBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
    );
  }

  @override
  String toString() =>
      'Budget(userId: $userId, periodType: $periodType, periodId: $periodId, totalBudget: $totalBudget, categoryBudgets: $categoryBudgets)';
}
