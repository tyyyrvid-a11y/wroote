/// Representa uma página de escrita dentro de um capítulo.
/// [contentJson] guarda o Delta do flutter_quill serializado em JSON.
class BookPage {
  static const String emptyContentJson = '[{"insert":"\\n"}]';

  final String id;
  final String chapterId;
  final String bookId;
  final String title;
  final int orderIndex;
  final String contentJson;
  final int wordCount;
  final DateTime updatedAt;

  const BookPage({
    required this.id,
    required this.chapterId,
    required this.bookId,
    required this.title,
    required this.orderIndex,
    this.contentJson = emptyContentJson,
    this.wordCount = 0,
    required this.updatedAt,
  });

  BookPage copyWith({
    String? title,
    int? orderIndex,
    String? contentJson,
    int? wordCount,
    DateTime? updatedAt,
  }) {
    return BookPage(
      id: id,
      chapterId: chapterId,
      bookId: bookId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      contentJson: contentJson ?? this.contentJson,
      wordCount: wordCount ?? this.wordCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'bookId': bookId,
      'title': title,
      'orderIndex': orderIndex,
      'contentJson': contentJson,
      'wordCount': wordCount,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory BookPage.fromMap(Map<String, Object?> map) {
    return BookPage(
      id: map['id'] as String,
      chapterId: map['chapterId'] as String,
      bookId: map['bookId'] as String,
      title: map['title'] as String,
      orderIndex: map['orderIndex'] as int,
      contentJson: map['contentJson'] as String? ?? emptyContentJson,
      wordCount: map['wordCount'] as int? ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }
}
