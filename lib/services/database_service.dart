import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/book.dart';
import '../models/book_core.dart';
import '../models/book_page.dart';
import '../models/chapter.dart';
import '../models/character.dart';

/// Camada de acesso a dados: um único arquivo SQLite local, sem backend.
/// Usa sqflite_common_ffi para rodar em Windows/macOS/Linux (desktop).
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final supportDir = await getApplicationSupportDirectory();
    final dbPath = p.join(supportDir.path, 'wroote.db');

    return openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            orderIndex INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE book_cores (
            bookId TEXT PRIMARY KEY,
            synopsis TEXT NOT NULL DEFAULT '',
            centralConflict TEXT NOT NULL DEFAULT '',
            pageEstimate INTEGER NOT NULL DEFAULT 0,
            introSynopsis TEXT NOT NULL DEFAULT '',
            developmentSynopsis TEXT NOT NULL DEFAULT '',
            climaxSynopsis TEXT NOT NULL DEFAULT '',
            endingSynopsis TEXT NOT NULL DEFAULT '',
            FOREIGN KEY(bookId) REFERENCES books(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE characters (
            id TEXT PRIMARY KEY,
            bookId TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            details TEXT NOT NULL DEFAULT '',
            orderIndex INTEGER NOT NULL,
            FOREIGN KEY(bookId) REFERENCES books(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE chapters (
            id TEXT PRIMARY KEY,
            bookId TEXT NOT NULL,
            title TEXT NOT NULL,
            orderIndex INTEGER NOT NULL,
            FOREIGN KEY(bookId) REFERENCES books(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE pages (
            id TEXT PRIMARY KEY,
            chapterId TEXT NOT NULL,
            bookId TEXT NOT NULL,
            title TEXT NOT NULL,
            orderIndex INTEGER NOT NULL,
            contentJson TEXT NOT NULL,
            wordCount INTEGER NOT NULL DEFAULT 0,
            updatedAt INTEGER NOT NULL,
            FOREIGN KEY(chapterId) REFERENCES chapters(id) ON DELETE CASCADE,
            FOREIGN KEY(bookId) REFERENCES books(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('CREATE INDEX idx_characters_book ON characters(bookId)');
        await db.execute('CREATE INDEX idx_chapters_book ON chapters(bookId)');
        await db.execute('CREATE INDEX idx_pages_chapter ON pages(chapterId)');
        await db.execute('CREATE INDEX idx_pages_book ON pages(bookId)');
      },
    );
  }

  // ---------------- Books ----------------

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final rows = await db.query('books', orderBy: 'orderIndex ASC');
    return rows.map(Book.fromMap).toList();
  }

  Future<Book?> getBook(String id) async {
    final db = await database;
    final rows = await db.query('books', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  Future<void> insertBook(Book book) async {
    final db = await database;
    await db.insert('books', book.toMap());
  }

  Future<void> updateBook(Book book) async {
    final db = await database;
    await db.update('books', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
  }

  Future<void> deleteBook(String id) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getNextBookOrderIndex() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(orderIndex) as maxOrder FROM books');
    final maxOrder = result.first['maxOrder'] as int?;
    return (maxOrder ?? -1) + 1;
  }

  /// Soma de palavras de todas as páginas de um livro — usada para estimar
  /// o progresso mostrado na Biblioteca.
  Future<int> getTotalWordCount(String bookId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(wordCount), 0) as total FROM pages WHERE bookId = ?',
      [bookId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<Map<String, int>> getWordCountsForAllBooks() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT bookId, COALESCE(SUM(wordCount), 0) as total FROM pages GROUP BY bookId',
    );
    return {for (final row in rows) row['bookId'] as String: (row['total'] as int?) ?? 0};
  }

  // ---------------- Book core ----------------

  Future<BookCore> getBookCore(String bookId) async {
    final db = await database;
    final rows = await db.query('book_cores', where: 'bookId = ?', whereArgs: [bookId], limit: 1);
    if (rows.isEmpty) return BookCore.empty(bookId);
    return BookCore.fromMap(rows.first);
  }

  Future<void> upsertBookCore(BookCore core) async {
    final db = await database;
    await db.insert('book_cores', core.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, int>> getPageEstimatesForAllBooks() async {
    final db = await database;
    final rows = await db.query('book_cores', columns: ['bookId', 'pageEstimate']);
    return {for (final row in rows) row['bookId'] as String: (row['pageEstimate'] as int?) ?? 0};
  }

  // ---------------- Characters ----------------

  Future<List<BookCharacter>> getCharacters(String bookId) async {
    final db = await database;
    final rows = await db.query('characters', where: 'bookId = ?', whereArgs: [bookId], orderBy: 'orderIndex ASC');
    return rows.map(BookCharacter.fromMap).toList();
  }

  Future<void> insertCharacter(BookCharacter character) async {
    final db = await database;
    await db.insert('characters', character.toMap());
  }

  Future<void> updateCharacter(BookCharacter character) async {
    final db = await database;
    await db.update('characters', character.toMap(), where: 'id = ?', whereArgs: [character.id]);
  }

  Future<void> deleteCharacter(String id) async {
    final db = await database;
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Chapters ----------------

  Future<List<Chapter>> getChapters(String bookId) async {
    final db = await database;
    final rows = await db.query('chapters', where: 'bookId = ?', whereArgs: [bookId], orderBy: 'orderIndex ASC');
    return rows.map(Chapter.fromMap).toList();
  }

  Future<void> insertChapter(Chapter chapter) async {
    final db = await database;
    await db.insert('chapters', chapter.toMap());
  }

  Future<void> updateChapter(Chapter chapter) async {
    final db = await database;
    await db.update('chapters', chapter.toMap(), where: 'id = ?', whereArgs: [chapter.id]);
  }

  Future<void> deleteChapter(String id) async {
    final db = await database;
    await db.delete('chapters', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Pages ----------------

  Future<List<BookPage>> getPages(String chapterId) async {
    final db = await database;
    final rows = await db.query('pages', where: 'chapterId = ?', whereArgs: [chapterId], orderBy: 'orderIndex ASC');
    return rows.map(BookPage.fromMap).toList();
  }

  Future<BookPage?> getPage(String id) async {
    final db = await database;
    final rows = await db.query('pages', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return BookPage.fromMap(rows.first);
  }

  Future<void> insertPage(BookPage page) async {
    final db = await database;
    await db.insert('pages', page.toMap());
  }

  Future<void> updatePage(BookPage page) async {
    final db = await database;
    await db.update('pages', page.toMap(), where: 'id = ?', whereArgs: [page.id]);
  }

  Future<void> deletePage(String id) async {
    final db = await database;
    await db.delete('pages', where: 'id = ?', whereArgs: [id]);
  }
}
