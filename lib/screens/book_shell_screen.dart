import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/book_core_provider.dart';
import '../services/editor_provider.dart';
import 'book_core_screen.dart';
import 'page_editor_screen.dart';

/// Contêiner de um livro aberto: alterna entre o Núcleo do Livro
/// (planejamento) e a Escrita de páginas, mantendo os dois providers
/// vivos enquanto o livro estiver aberto.
class BookShellScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  const BookShellScreen({super.key, required this.bookId, required this.bookTitle});

  @override
  State<BookShellScreen> createState() => _BookShellScreenState();
}

class _BookShellScreenState extends State<BookShellScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookCoreProvider(widget.bookId)),
        ChangeNotifierProvider(create: (_) => EditorProvider(widget.bookId)),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.bookTitle, overflow: TextOverflow.ellipsis),
          bottom: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodySmall?.color,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.map_outlined), text: 'Núcleo do livro'),
              Tab(icon: Icon(Icons.edit_note_outlined), text: 'Escrita'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            BookCoreScreen(),
            PageEditorScreen(),
          ],
        ),
      ),
    );
  }
}
