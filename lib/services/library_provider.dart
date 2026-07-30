import 'package:flutter/foundation.dart';

import '../models/book.dart';
import 'database_service.dart';
import 'id_generator.dart';

class BookWithProgress {
  final Book book;
  final int wordCount;
  final int pageEstimate;

  BookWithProgress({required this.book, required this.wordCount, required this.pageEstimate});

  /// Progresso estimado (0..1). Sem estimativa de páginas definida no
  /// núcleo do livro, cai de volta para uma curva suave baseada apenas
  /// na contagem de palavras, para a barra nunca ficar "travada" em zero.
  double get progress {
    if (pageEstimate > 0) {
      final estimatedWords = pageEstimate * 250;
      if (estimatedWords <= 0) return 0;
      return (wordCount / estimatedWords).clamp(0.0, 1.0);
    }
    if (wordCount <= 0) return 0;
    return (wordCount / (wordCount + 5000)).clamp(0.0, 0.95);
  }
}

/// Estado da tela Biblioteca: lista de livros, progresso e busca por título.
class LibraryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Book> _books = [];
  Map<String, int> _wordCounts = {};
  Map<String, int> _pageEstimates = {};
  String _searchQuery = '';
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<BookWithProgress> get books {
    final filtered = _searchQuery.trim().isEmpty
        ? _books
        : _books.where((b) => b.title.toLowerCase().contains(_searchQuery.trim().toLowerCase()));
    final list = filtered
        .map((b) => BookWithProgress(
              book: b,
              wordCount: _wordCounts[b.id] ?? 0,
              pageEstimate: _pageEstimates[b.id] ?? 0,
            ))
        .toList();
    list.sort((a, b) => a.book.orderIndex.compareTo(b.book.orderIndex));
    return list;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _books = await _db.getAllBooks();
    _wordCounts = await _db.getWordCountsForAllBooks();
    _pageEstimates = await _db.getPageEstimatesForAllBooks();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<Book> createBook(String title) async {
    final now = DateTime.now();
    final orderIndex = await _db.getNextBookOrderIndex();
    final book = Book(
      id: generateId(),
      title: title.trim().isEmpty ? 'Livro sem título' : title.trim(),
      createdAt: now,
      updatedAt: now,
      orderIndex: orderIndex,
    );
    await _db.insertBook(book);
    await load();
    return book;
  }

  Future<void> renameBook(String bookId, String newTitle) async {
    final book = _books.firstWhere((b) => b.id == bookId);
    final updated = book.copyWith(
      title: newTitle.trim().isEmpty ? book.title : newTitle.trim(),
      updatedAt: DateTime.now(),
    );
    await _db.updateBook(updated);
    await load();
  }

  Future<void> deleteBook(String bookId) async {
    await _db.deleteBook(bookId);
    await load();
  }
}
