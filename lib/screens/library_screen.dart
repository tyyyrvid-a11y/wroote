import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/library_provider.dart';
import '../theme/theme_mode_controller.dart';
import '../widgets/book_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/text_prompt_dialog.dart';
import 'book_shell_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().load();
    });
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookShellScreen(bookId: book.id, bookTitle: book.title)),
    );
    if (mounted) context.read<LibraryProvider>().load();
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
  }

  Future<void> _deleteBook(BookWithProgress entry) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir "${entry.book.title}"?',
      message: 'Todo o planejamento, personagens, capítulos e páginas deste livro serão apagados permanentemente.',
    );
    if (confirmed) {
      await context.read<LibraryProvider>().deleteBook(entry.book.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final themeModeController = context.watch<ThemeModeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wroote'),
        actions: [
          IconButton(
            tooltip: 'Alternar tema',
            icon: Icon(themeModeController.isDark(context) ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => themeModeController.toggle(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBook,
        icon: const Icon(Icons.add),
        label: const Text('Novo livro'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: TextField(
                onChanged: library.setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Buscar por título…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(child: _buildBody(library)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LibraryProvider library) {
    if (library.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final books = library.books;

    if (books.isEmpty) {
      final hasQuery = library.searchQuery.trim().isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                hasQuery ? 'Nenhum livro encontrado.' : 'Nenhum livro ainda.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!hasQuery) ...[
                const SizedBox(height: 6),
                Text(
                  'Toque em "Novo livro" para começar a escrever.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 150,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final entry = books[index];
        return BookCard(
          entry: entry,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookShellScreen(bookId: entry.book.id, bookTitle: entry.book.title),
              ),
            );
            if (mounted) context.read<LibraryProvider>().load();
          },
          onRename: () => _renameBook(entry),
          onDelete: () => _deleteBook(entry),
        );
      },
    );
  }
}
