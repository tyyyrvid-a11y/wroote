import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/library_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/theme_mode_controller.dart';
import '../widgets/book_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/counters.dart';
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
    // `books` monta, filtra e ordena a lista a cada chamada: uma vez por
    // build, reaproveitada pelo cabeçalho e pelo corpo.
    final books = library.isLoading ? const <BookWithProgress>[] : library.books;

    // Atalhos de teclado: a diferença mais direta entre um app de desktop e
    // um app de celular rodando numa janela.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _createBook,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _searchFocus.requestFocus,
      },
      child: Focus(
        autofocus: true,
        child: AppScaffold(
          body: SafeArea(
            child: Column(
              children: [
                _LibraryHeader(
                  searchController: _searchController,
                  searchFocus: _searchFocus,
                  onSearchChanged: library.setSearchQuery,
                  onCreate: _createBook,
                  bookCount: library.isLoading ? null : books.length,
                ),
                Expanded(child: _buildBody(library, books)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LibraryProvider library, List<BookWithProgress> books) {
    if (library.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (books.isEmpty) {
      return _EmptyState(
        hasQuery: library.searchQuery.trim().isNotEmpty,
        onCreate: _createBook,
      );
    }

    return ContentColumn(
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 330,
          mainAxisExtent: 150,
          // O espaço entre cartões é o que os separa agora que nenhum deles
          // tem sombra — por isso é generoso, e igual nos dois eixos.
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
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

/// Barra superior da biblioteca: faixa de largura total, cor de painel e uma
/// linha de 1px embaixo — a moldura da janela, não um bloco flutuante.
///
/// A ação principal mora aqui, à direita, como um retângulo ancorado no
/// fluxo. Um botão redondo flutuando sobre o canto inferior da tela é um
/// padrão de celular: existe porque o polegar não alcança o topo.
class _LibraryHeader extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreate;
  final int? bookCount;

  const _LibraryHeader({
    required this.searchController,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.onCreate,
    required this.bookCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = context.surfaces;

    return Container(
      decoration: BoxDecoration(
        color: surfaces.panel,
        border: Border(bottom: BorderSide(color: surfaces.hairline)),
      ),
      child: ContentColumn(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
        child: Row(
          children: [
            Text('Wroote', style: theme.textTheme.headlineLarge),
            const ToolbarSeparator(height: 18),
            Text('Biblioteca', style: theme.textTheme.bodySmall),
            if (bookCount != null && bookCount! > 0) ...[
              const SizedBox(width: 10),
              MonoText(
                '${formatCount(bookCount!)} ${bookCount == 1 ? 'livro' : 'livros'}',
                size: 11,
                color: theme.textTheme.labelSmall?.color,
              ),
            ],
            const Spacer(),
            SizedBox(
              width: 260,
              child: TextField(
                controller: searchController,
                focusNode: searchFocus,
                onChanged: onSearchChanged,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Buscar por título',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                  // O atalho impresso dentro do campo, em mono: é a mesma
                  // convenção dos menus de qualquer app de desktop.
                  suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(left: 6, right: 9),
                    child: MonoText(
                      'Ctrl+F',
                      size: 10.5,
                      color: theme.textTheme.labelSmall?.color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const _SoundToggle(),
            const _ThemeToggle(),
            const ToolbarSeparator(height: 18),
            PrimaryButton(
              label: 'Novo livro',
              icon: Icons.add,
              onPressed: onCreate,
              sound: UiSound.open,
            ),
          ],
        ),
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
      sound: UiSound.toggle,
      onPressed: () => controller.toggle(context),
    );
  }
}

/// Estado vazio: texto e uma ação. Sem ilustração, sem círculo decorativo —
/// a tela vazia de um editor deve parecer uma folha em branco.
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
            Text(
              hasQuery ? 'Nenhum livro encontrado' : 'Nenhum livro ainda',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Tente outro termo de busca.'
                  : 'Comece pelo planejamento — o resto vem depois.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Criar o primeiro livro',
                icon: Icons.add,
                onPressed: onCreate,
                sound: UiSound.open,
              ),
              const SizedBox(height: 12),
              MonoText(
                'ou Ctrl+N',
                size: 11,
                color: theme.textTheme.labelSmall?.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
