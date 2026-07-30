import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../models/book_page.dart';
import '../models/chapter.dart';
import 'database_service.dart';
import 'id_generator.dart';

const _autosaveDelay = Duration(milliseconds: 900);
final RegExp _wordSplitter = RegExp(r'\s+');

int countWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(_wordSplitter).where((w) => w.isNotEmpty).length;
}

/// Estado da tela "Escrita de páginas": árvore de capítulos/páginas,
/// o [QuillController] da página aberta, contagem de palavras em tempo
/// real e autosave com debounce a cada alteração do documento.
class EditorProvider extends ChangeNotifier {
  final String bookId;
  final DatabaseService _db = DatabaseService.instance;

  EditorProvider(this.bookId) {
    _init();
  }

  bool isLoading = true;
  List<Chapter> chapters = [];
  final Map<String, List<BookPage>> _pagesByChapter = {};

  String? currentChapterId;
  String? currentPageId;
  QuillController controller = QuillController.basic();
  int wordCount = 0;

  Timer? _saveDebounce;

  List<BookPage> pagesFor(String chapterId) => List.unmodifiable(_pagesByChapter[chapterId] ?? const []);

  BookPage? get currentPage => currentPageId == null ? null : _findPage(currentPageId!);

  Future<void> _init() async {
    chapters = await _db.getChapters(bookId);

    if (chapters.isEmpty) {
      await _createChapterInternal(title: 'Capítulo 1');
    } else {
      for (final chapter in chapters) {
        _pagesByChapter[chapter.id] = await _db.getPages(chapter.id);
      }
    }

    final firstChapter = chapters.first;
    var pages = _pagesByChapter[firstChapter.id] ?? const [];
    if (pages.isEmpty) {
      await _createPageInternal(chapterId: firstChapter.id, title: 'Página 1');
      pages = _pagesByChapter[firstChapter.id]!;
    }

    await _openPage(pages.first.id, chapterId: firstChapter.id, notify: false);

    isLoading = false;
    notifyListeners();
  }

  BookPage? _findPage(String pageId) {
    for (final pages in _pagesByChapter.values) {
      for (final page in pages) {
        if (page.id == pageId) return page;
      }
    }
    return null;
  }

  void _replacePageInMemory(BookPage updated) {
    final list = _pagesByChapter[updated.chapterId];
    if (list == null) return;
    final index = list.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;
    list[index] = updated;
  }

  Future<void> openPage(String pageId) async {
    if (pageId == currentPageId) return;
    await _flushCurrentPage();
    final page = _findPage(pageId);
    if (page == null) return;
    await _openPage(pageId, chapterId: page.chapterId, notify: true);
  }

  Future<void> _openPage(String pageId, {required String chapterId, required bool notify}) async {
    final page = _findPage(pageId);
    if (page == null) return;

    controller.removeListener(_onDocumentChanged);

    Document document;
    try {
      document = Document.fromJson(jsonDecode(page.contentJson));
    } catch (_) {
      document = Document();
    }

    controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    controller.addListener(_onDocumentChanged);

    currentPageId = page.id;
    currentChapterId = chapterId;
    wordCount = countWords(document.toPlainText());

    if (notify) notifyListeners();
  }

  void _onDocumentChanged() {
    wordCount = countWords(controller.document.toPlainText());
    notifyListeners();

    _saveDebounce?.cancel();
    _saveDebounce = Timer(_autosaveDelay, _saveCurrentPage);
  }

  Future<void> _saveCurrentPage() async {
    final pageId = currentPageId;
    if (pageId == null) return;
    final page = _findPage(pageId);
    if (page == null) return;

    final json = jsonEncode(controller.document.toDelta().toJson());
    final updated = page.copyWith(
      contentJson: json,
      wordCount: wordCount,
      updatedAt: DateTime.now(),
    );
    _replacePageInMemory(updated);
    await _db.updatePage(updated);
  }

  Future<void> _flushCurrentPage() async {
    _saveDebounce?.cancel();
    await _saveCurrentPage();
  }

  /// Chamado ao sair da tela de escrita para garantir que nada se perca.
  Future<void> flush() => _flushCurrentPage();

  // ---------------- Capítulos ----------------

  Future<Chapter> _createChapterInternal({required String title}) async {
    final chapter = Chapter(
      id: generateId(),
      bookId: bookId,
      title: title,
      orderIndex: chapters.length,
    );
    await _db.insertChapter(chapter);
    chapters = [...chapters, chapter];
    _pagesByChapter[chapter.id] = [];
    return chapter;
  }

  Future<void> _createPageInternal({required String chapterId, required String title}) async {
    final pages = _pagesByChapter[chapterId] ?? [];
    final page = BookPage(
      id: generateId(),
      chapterId: chapterId,
      bookId: bookId,
      title: title,
      orderIndex: pages.length,
      updatedAt: DateTime.now(),
    );
    await _db.insertPage(page);
    _pagesByChapter[chapterId] = [...pages, page];
  }

  Future<void> addChapter() async {
    await _flushCurrentPage();
    final chapter = await _createChapterInternal(title: 'Capítulo ${chapters.length + 1}');
    await _createPageInternal(chapterId: chapter.id, title: 'Página 1');
    final page = _pagesByChapter[chapter.id]!.first;
    await _openPage(page.id, chapterId: chapter.id, notify: false);
    notifyListeners();
  }

  Future<void> renameChapter(String chapterId, String title) async {
    final index = chapters.indexWhere((c) => c.id == chapterId);
    if (index == -1) return;
    final updated = chapters[index].copyWith(title: title.trim().isEmpty ? chapters[index].title : title.trim());
    chapters = [...chapters]..[index] = updated;
    notifyListeners();
    await _db.updateChapter(updated);
  }

  Future<void> deleteChapter(String chapterId) async {
    if (chapters.length <= 1) return; // sempre deve sobrar ao menos um capítulo
    final wasCurrent = chapterId == currentChapterId;

    await _db.deleteChapter(chapterId);
    chapters = chapters.where((c) => c.id != chapterId).toList();
    _pagesByChapter.remove(chapterId);

    if (wasCurrent) {
      final fallbackChapter = chapters.first;
      var pages = _pagesByChapter[fallbackChapter.id] ?? const [];
      if (pages.isEmpty) {
        await _createPageInternal(chapterId: fallbackChapter.id, title: 'Página 1');
        pages = _pagesByChapter[fallbackChapter.id]!;
      }
      await _openPage(pages.first.id, chapterId: fallbackChapter.id, notify: false);
    }
    notifyListeners();
  }

  // ---------------- Páginas ----------------

  Future<void> addPage(String chapterId) async {
    await _flushCurrentPage();
    final pages = _pagesByChapter[chapterId] ?? [];
    await _createPageInternal(chapterId: chapterId, title: 'Página ${pages.length + 1}');
    final newPage = _pagesByChapter[chapterId]!.last;
    await _openPage(newPage.id, chapterId: chapterId, notify: false);
    notifyListeners();
  }

  Future<void> renamePage(String pageId, String title) async {
    final page = _findPage(pageId);
    if (page == null) return;
    final updated = page.copyWith(title: title.trim().isEmpty ? page.title : title.trim());
    _replacePageInMemory(updated);
    notifyListeners();
    await _db.updatePage(updated);
  }

  Future<void> deletePage(String pageId) async {
    final page = _findPage(pageId);
    if (page == null) return;
    final chapterId = page.chapterId;
    final pages = _pagesByChapter[chapterId] ?? [];
    if (pages.length <= 1) return; // sempre deve sobrar ao menos uma página no capítulo

    final wasCurrent = pageId == currentPageId;

    await _db.deletePage(pageId);
    _pagesByChapter[chapterId] = pages.where((p) => p.id != pageId).toList();

    if (wasCurrent) {
      final remaining = _pagesByChapter[chapterId]!;
      await _openPage(remaining.first.id, chapterId: chapterId, notify: false);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _saveCurrentPage();
    controller.removeListener(_onDocumentChanged);
    controller.dispose();
    super.dispose();
  }
}
