import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/book_core.dart';
import '../models/character.dart';
import 'database_service.dart';
import 'id_generator.dart';

const _autosaveDelay = Duration(milliseconds: 700);

/// Estado da tela "Núcleo do Livro": sinopse, conflito central, estimativa
/// de páginas, sinopses por ato e a lista de personagens. Cada edição
/// dispara um autosave com debounce, sem precisar de um botão "Salvar".
class BookCoreProvider extends ChangeNotifier {
  final String bookId;
  final DatabaseService _db = DatabaseService.instance;

  BookCoreProvider(this.bookId) {
    _core = BookCore.empty(bookId);
    _load();
  }

  late BookCore _core;
  List<BookCharacter> _characters = [];
  bool isLoading = true;

  Timer? _coreDebounce;
  final Map<String, Timer> _characterDebounces = {};

  BookCore get core => _core;
  List<BookCharacter> get characters => List.unmodifiable(_characters);

  BookCharacter? _findCharacter(String id) {
    for (final character in _characters) {
      if (character.id == id) return character;
    }
    return null;
  }

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();

    _core = await _db.getBookCore(bookId);
    _characters = await _db.getCharacters(bookId);

    isLoading = false;
    notifyListeners();
  }

  void _updateCore(BookCore updated) {
    _core = updated;
    notifyListeners();
    _coreDebounce?.cancel();
    _coreDebounce = Timer(_autosaveDelay, () {
      _db.upsertBookCore(_core);
    });
  }

  void updateSynopsis(String value) => _updateCore(_core.copyWith(synopsis: value));
  void updateCentralConflict(String value) => _updateCore(_core.copyWith(centralConflict: value));
  void updateIntroSynopsis(String value) => _updateCore(_core.copyWith(introSynopsis: value));
  void updateDevelopmentSynopsis(String value) => _updateCore(_core.copyWith(developmentSynopsis: value));
  void updateClimaxSynopsis(String value) => _updateCore(_core.copyWith(climaxSynopsis: value));
  void updateEndingSynopsis(String value) => _updateCore(_core.copyWith(endingSynopsis: value));

  void updatePageEstimate(int value) {
    _updateCore(_core.copyWith(pageEstimate: value < 0 ? 0 : value));
  }

  Future<void> addCharacter({String name = 'Novo personagem'}) async {
    final character = BookCharacter(
      id: generateId(),
      bookId: bookId,
      name: name,
      orderIndex: _characters.length,
    );
    _characters = [..._characters, character];
    notifyListeners();
    await _db.insertCharacter(character);
  }

  void updateCharacter(BookCharacter updated) {
    final index = _characters.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    final next = [..._characters];
    next[index] = updated;
    _characters = next;
    notifyListeners();

    _characterDebounces[updated.id]?.cancel();
    _characterDebounces[updated.id] = Timer(_autosaveDelay, () {
      _db.updateCharacter(updated);
    });
  }

  Future<void> deleteCharacter(String characterId) async {
    _characterDebounces.remove(characterId)?.cancel();
    _characters = _characters.where((c) => c.id != characterId).toList();
    notifyListeners();
    await _db.deleteCharacter(characterId);
  }

  /// Força a gravação imediata, ignorando o debounce — usado ao sair da tela.
  Future<void> flush() async {
    _coreDebounce?.cancel();
    await _db.upsertBookCore(_core);

    final pendingIds = _characterDebounces.keys.toList();
    for (final id in pendingIds) {
      _characterDebounces.remove(id)?.cancel();
      final character = _findCharacter(id);
      if (character != null) await _db.updateCharacter(character);
    }
  }

  @override
  void dispose() {
    _coreDebounce?.cancel();
    unawaited(_db.upsertBookCore(_core));

    final pendingIds = _characterDebounces.keys.toList();
    for (final id in pendingIds) {
      _characterDebounces.remove(id)?.cancel();
      final character = _findCharacter(id);
      if (character != null) unawaited(_db.updateCharacter(character));
    }
    super.dispose();
  }
}
