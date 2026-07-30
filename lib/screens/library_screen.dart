import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/library_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/theme_mode_controller.dart';
import '../widgets/book_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/surfaces.dart';
import '../widgets/text_prompt_dialog.dart';
import 'book_shell_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _createBook() async {
    final title = await TextPromptDialog.show(
      context,
      title: 'Novo livro',
      label: 'Título do livro',
      confirmLabel: 'Criar',
    );
    if (title == null || !mounted) return;
    final book = await context.read<LibraryProvider>().createBook(title);
    if (!mounted) return;
    // Sem som de "sucesso" aqui: `_openBook` toca logo em seguida e os dois
    // efeitos colados viram um borrão em vez de dois sinais.
    await _openBook(book.id, book.title);
  }

  Future<void> _openBook(String id, String title) async {
    context.sounds.play(UiSound.open);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookShellScreen(bookId: id, bookTitle: title)),
    );
    if (!mounted) return;
    context.sounds.play(UiSound.close);
    context.read<LibraryProvider>().load();
  }

  Future<void> _renameBook(BookWithProgress entry) async {
    final title = await TextPromptDialog.show(
      context,
      title: 'Renomear livro',
      label: 'Título do livro',
      initialValue: entry.book.title,
      confirmLabel: 'Renomear',
    );
    if (title == null || !mounted) return;
    await context.read<LibraryProvider>().renameBook(entry.book.id, title);
    if (mounted) context.sounds.play(UiSound.success);
  }

  Future<void> _deleteBook(BookWithProgress entry) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir "${entry.book.title}"?',
      message:
          'Todo o planejamento, personagens, capítulos e páginas deste livro serão apagados permanentemente.',
    );
    if (!confirmed || !mounted) return;
    await context.read<LibraryProvider>().deleteBook(entry.book.id);
    if (mounted) context.sounds.play(UiSound.delete);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    // Atalhos de teclado: a diferença mais direta entre um app de desktop e
    // um app de celular rodando numa janela.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _createBook,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _searchFocus.requestFocus,
      },
      child: Focus(
        autofocus: true,
        child: GradientScaffold(
          body: SafeArea(
            child: Column(
              children: [
                _LibraryHeader(
                  searchController: _searchController,
                  searchFocus: _searchFocus,
                  onSearchChanged: library.setSearchQuery,
                  onCreate: _createBook,
                ),
                Expanded(child: _buildBody(library)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LibraryProvider library) {
    if (library.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // `books` monta e ordena a lista a cada chamada, então vale guardar.
    final books = library.books;

    if (books.isEmpty) {
      return _EmptyState(
        hasQuery: library.searchQuery.trim().isNotEmpty,
        onCreate: _createBook,
      );
    }

    return ContentColumn(
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 40),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          // Cartões maiores que os 280px anteriores: numa tela de desktop,
          // cartões pequenos demais viram uma grade de ícones e desperdiçam
          // o espaço que permitiria mostrar mais informação por livro.
          maxCrossAxisExtent: 340,
          mainAxisExtent: 176,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final entry = books[index];
          return StaggeredEntrance(
            // A chave amarra a animação ao livro, não à posição: sem isso,
            // filtrar a busca reanimaria cartões que já estavam na tela.
            key: ValueKey(entry.book.id),
            index: index,
            child: BookCard(
              entry: entry,
              onTap: () => _openBook(entry.book.id, entry.book.title),
              onRename: () => _renameBook(entry),
              onDelete: () => _deleteBook(entry),
            ),
          );
        },
      ),
    );
  }
}

/// Barra superior da biblioteca. Substitui a [AppBar] + [FloatingActionButton]
/// do layout anterior: no desktop, a ação principal mora na barra de
/// ferramentas junto das outras, não flutuando sobre o canto da tela.
class _LibraryHeader extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreate;

  const _LibraryHeader({
    required this.searchController,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContentColumn(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                // O título é o único lugar do app onde o gradiente de acento
                // aparece sobre texto — mantém a marca presente sem pintar
                // o resto da interface.
                shaderCallback: (bounds) => context.surfaces.accent.createShader(bounds),
                child: Text(
                  'Wroote',
                  style: theme.textTheme.displayMedium?.copyWith(color: Colors.white),
                ),
              ),
              Text('Sua biblioteca', style: theme.textTheme.bodySmall),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 300,
            child: TextField(
              controller: searchController,
              focusNode: searchFocus,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Buscar por título…   (Ctrl+F)',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const _SoundToggle(),
          const SizedBox(width: 4),
          const _ThemeToggle(),
          const SizedBox(width: 16),
          AccentButton(
            label: 'Novo livro',
            icon: Icons.add,
            onPressed: onCreate,
            sound: UiSound.open,
          ),
        ],
      ),
    );
  }
}

class _SoundToggle extends StatelessWidget {
  const _SoundToggle();

  @override
  Widget build(BuildContext context) {
    final sounds = context.watch<SoundService>();
    return AppIconButton(
      icon: sounds.enabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
      tooltip: sounds.enabled ? 'Desligar sons' : 'Ligar sons',
      size: 20,
      // O próprio `setEnabled` toca o som de confirmação quando liga; um
      // som aqui seria tocado antes da mudança e confundiria o feedback.
      sound: UiSound.toggle,
      onPressed: () => sounds.setEnabled(!sounds.enabled),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeModeController>();
    final isDark = controller.isDark(context);
    return AppIconButton(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      tooltip: isDark ? 'Tema claro' : 'Tema escuro',
      size: 20,
      sound: UiSound.toggle,
      onPressed: () => controller.toggle(context),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback onCreate;

  const _EmptyState({required this.hasQuery, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: StaggeredEntrance(
        index: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: context.surfaces.card,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outline),
                boxShadow: context.surfaces.cardShadow,
              ),
              child: Icon(
                hasQuery ? Icons.search_off_outlined : Icons.menu_book_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasQuery ? 'Nenhum livro encontrado.' : 'Nenhum livro ainda.',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Tente outro termo de busca.'
                  : 'Comece pelo planejamento — o resto vem depois.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 24),
              AccentButton(
                label: 'Criar meu primeiro livro',
                icon: Icons.add,
                onPressed: onCreate,
                sound: UiSound.open,
              ),
              const SizedBox(height: 12),
              Text('ou pressione Ctrl+N', style: theme.textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}
