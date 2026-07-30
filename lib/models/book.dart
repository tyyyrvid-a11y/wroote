class Book {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int orderIndex;

  const Book({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.orderIndex,
  });

  Book copyWith({
    String? title,
    DateTime? updatedAt,
    int? orderIndex,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'orderIndex': orderIndex,
    };
  }

  factory Book.fromMap(Map<String, Object?> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      orderIndex: map['orderIndex'] as int,
    );
  }
}
