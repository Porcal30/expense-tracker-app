class Category {
  final String id;
  final String userId;
  final String name;
  final int colorValue;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.colorValue,
  });

  factory Category.fromMap(Map<String, dynamic> map, String id) {
    return Category(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      colorValue: map['colorValue'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'colorValue': colorValue,
    };
  }
}