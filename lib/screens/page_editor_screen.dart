import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import '../models/book_page.dart';
import '../services/editor_provider.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import '../widgets/autosave_field.dart';
import '../widgets/chapter_page_sidebar.dart';
import '../widgets/word_count_badge.dart';

/// Tela de escrita: editor de texto rico (flutter_quill) com negrito e
/// itálico, contador de palavras em tempo real e navegação entre
/// páginas/capítulos pela barra lateral. Autosave com debounce.
class PageEditorScreen extends StatelessWidget {
  const PageEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final currentPage = provider.currentPage;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChapterPageSidebar(provider: provider),
        VerticalDivider(width: 1, color: theme.colorScheme.outline),
        Expanded(
          child: Column(
            children: [
              _EditorHeader(provider: provider, currentPage: currentPage),
              _ToolbarBar(controller: provider.controller, pageId: currentPage?.id),
              Expanded(child: _WritingSurface(provider: provider, pageId: currentPage?.id)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditorHeader extends StatelessWidget {
  final EditorProvider provider;
  final BookPage? currentPage;

  const _EditorHeader({required this.provider, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    // Cópia local: um campo de widget não sofre promoção de tipo, então
    // `currentPage.id` depois de um `!= null` não compilaria.
    final page = currentPage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.editorMaxWidth),
          child: Row(
            children: [
              Expanded(
                child: page == null
                    ? const SizedBox.shrink()
                    : AutosaveField(
                        key: ValueKey('title-${page.id}'),
                        initialValue: page.title,
                        onChanged: (value) => provider.renamePage(page.id, value),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
              ),
              const SizedBox(width: 16),
              WordCountBadge(count: provider.wordCount),
            ],
          ),
        ),
      ),
    );
  }
}

/// A barra de formatação numa faixa própria, com o gradiente de "chrome" e
/// uma borda embaixo. Solta sobre o fundo ela flutuava sem pertencer a
/// nada; numa faixa, fica claro que é a moldura da folha logo abaixo.
class _ToolbarBar extends StatelessWidget {
  final QuillController controller;
  final String? pageId;

  const _ToolbarBar({required this.controller, required this.pageId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: context.surfaces.chrome,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
          bottom: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.editorMaxWidth),
          child: QuillSimpleToolbar(
            key: ValueKey('toolbar-$pageId'),
            controller: controller,
            config: const QuillSimpleToolbarConfig(),
          ),
        ),
      ),
    );
  }
}

/// A "folha" de escrita: uma coluna centralizada e limitada em largura,
/// sobre o fundo da janela.
///
/// É a mudança que mais separa esta tela de um editor de celular esticado:
/// texto corrido ocupando 2000px de largura é impossível de ler, porque o
/// olho perde a linha no caminho de volta.
class _WritingSurface extends StatelessWidget {
  final EditorProvider provider;
  final String? pageId;

  const _WritingSurface({required this.provider, required this.pageId});

  @override
  Widget build(BuildContext context) {
    final serifBody = AppTheme.editorBodyStyle(context);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.editorMaxWidth + 96),
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          decoration: BoxDecoration(
            gradient: context.surfaces.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
            border: Border.all(color: theme.colorScheme.outline),
            boxShadow: context.surfaces.cardShadow,
          ),
          child: Theme(
            // O Quill lê o corpo do texto do tema, então a troca para a
            // serifada acontece aqui e vale só para dentro do editor.
            data: theme.copyWith(
              textTheme: theme.textTheme.copyWith(
                bodyLarge: serifBody,
                bodyMedium: serifBody,
                bodySmall: serifBody.copyWith(fontSize: 14),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 32, 40, 8),
              child: QuillEditor.basic(
                key: ValueKey('editor-$pageId'),
                controller: provider.controller,
                config: const QuillEditorConfig(
                  padding: EdgeInsets.only(bottom: 24),
                  placeholder: 'Comece a escrever…',
                  scrollable: true,
                  expands: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
