class Chapter {
  final String id;
  final String bookId;
  final String title;
  final int orderIndex;

  const Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.orderIndex,
  });

  Chapter copyWith({String? title, int? orderIndex}) {
    return Chapter(
      id: id,
      bookId: bookId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'orderIndex': orderIndex,
    };
  }

  factory Chapter.fromMap(Map<String, Object?> map) {
    return Chapter(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      title: map['title'] as String,
      orderIndex: map['orderIndex'] as int,
    );
  }
}
