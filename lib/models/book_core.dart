/// Núcleo de planejamento de um livro: sinopse geral, conflito central,
/// estimativa de páginas e as sinopses de cada ato da história.
class BookCore {
  final String bookId;
  final String synopsis;
  final String centralConflict;
  final int pageEstimate;
  final String introSynopsis;
  final String developmentSynopsis;
  final String climaxSynopsis;
  final String endingSynopsis;

  const BookCore({
    required this.bookId,
    this.synopsis = '',
    this.centralConflict = '',
    this.pageEstimate = 0,
    this.introSynopsis = '',
    this.developmentSynopsis = '',
    this.climaxSynopsis = '',
    this.endingSynopsis = '',
  });

  factory BookCore.empty(String bookId) => BookCore(bookId: bookId);

  BookCore copyWith({
    String? synopsis,
    String? centralConflict,
    int? pageEstimate,
    String? introSynopsis,
    String? developmentSynopsis,
    String? climaxSynopsis,
    String? endingSynopsis,
  }) {
    return BookCore(
      bookId: bookId,
      synopsis: synopsis ?? this.synopsis,
      centralConflict: centralConflict ?? this.centralConflict,
      pageEstimate: pageEstimate ?? this.pageEstimate,
      introSynopsis: introSynopsis ?? this.introSynopsis,
      developmentSynopsis: developmentSynopsis ?? this.developmentSynopsis,
      climaxSynopsis: climaxSynopsis ?? this.climaxSynopsis,
      endingSynopsis: endingSynopsis ?? this.endingSynopsis,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'bookId': bookId,
      'synopsis': synopsis,
      'centralConflict': centralConflict,
      'pageEstimate': pageEstimate,
      'introSynopsis': introSynopsis,
      'developmentSynopsis': developmentSynopsis,
      'climaxSynopsis': climaxSynopsis,
      'endingSynopsis': endingSynopsis,
    };
  }

  factory BookCore.fromMap(Map<String, Object?> map) {
    return BookCore(
      bookId: map['bookId'] as String,
      synopsis: map['synopsis'] as String? ?? '',
      centralConflict: map['centralConflict'] as String? ?? '',
      pageEstimate: map['pageEstimate'] as int? ?? 0,
      introSynopsis: map['introSynopsis'] as String? ?? '',
      developmentSynopsis: map['developmentSynopsis'] as String? ?? '',
      climaxSynopsis: map['climaxSynopsis'] as String? ?? '',
      endingSynopsis: map['endingSynopsis'] as String? ?? '',
    );
  }
}
