class BookCharacter {
  final String id;
  final String bookId;
  final String name;
  final String description;
  final String details;
  final int orderIndex;

  const BookCharacter({
    required this.id,
    required this.bookId,
    required this.name,
    this.description = '',
    this.details = '',
    required this.orderIndex,
  });

  BookCharacter copyWith({
    String? name,
    String? description,
    String? details,
    int? orderIndex,
  }) {
    return BookCharacter(
      id: id,
      bookId: bookId,
      name: name ?? this.name,
      description: description ?? this.description,
      details: details ?? this.details,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'name': name,
      'description': description,
      'details': details,
      'orderIndex': orderIndex,
    };
  }

  factory BookCharacter.fromMap(Map<String, Object?> map) {
    return BookCharacter(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      details: map['details'] as String? ?? '',
      orderIndex: map['orderIndex'] as int,
    );
  }
}
