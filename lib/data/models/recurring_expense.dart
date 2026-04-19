import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringExpense {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String categoryId;
  final String? note;
  /// One of: `daily`, `weekly`, `monthly`.
  final String frequency;
  final DateTime startDate;
  final DateTime? lastGeneratedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringExpense({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.frequency,
    required this.startDate,
    this.lastGeneratedDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringExpense.fromMap(Map<String, dynamic> map, String id) {
    return RecurringExpense(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      categoryId: map['categoryId'] ?? '',
      note: map['note'] as String?,
      frequency: map['frequency'] ?? 'monthly',
      startDate: (map['startDate'] as Timestamp).toDate(),
      lastGeneratedDate: map['lastGeneratedDate'] != null
          ? (map['lastGeneratedDate'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'frequency': frequency,
      'startDate': Timestamp.fromDate(startDate),
      if (lastGeneratedDate != null)
        'lastGeneratedDate': Timestamp.fromDate(lastGeneratedDate!),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RecurringExpense copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? categoryId,
    String? note,
    String? frequency,
    DateTime? startDate,
    DateTime? lastGeneratedDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
