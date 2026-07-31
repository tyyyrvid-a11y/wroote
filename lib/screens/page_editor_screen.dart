import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import '../models/book_page.dart';
import '../services/editor_provider.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import '../widgets/autosave_field.dart';
import '../widgets/chapter_page_sidebar.dart';
import '../widgets/counters.dart';
import '../widgets/editor_toolbar.dart';

/// Tela de escrita: editor de texto rico (flutter_quill) com a barra de
/// formatação própria do app, contador de palavras em tempo real e navegação
/// entre páginas/capítulos pela barra lateral. Autosave com debounce.
class PageEditorScreen extends StatelessWidget {
  const PageEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final currentPage = provider.currentPage;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChapterPageSidebar(provider: provider),
        VerticalDivider(width: 1, color: context.surfaces.hairline),
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

/// Cabeçalho da folha: o capítulo acima, o nome da página em serifada e a
/// contagem de palavras à direita.
///
/// A linha do capítulo existe para fechar a hierarquia — sem ela, o nome da
/// página fica solto e o autor perde de vista onde está no livro.
class _EditorHeader extends StatelessWidget {
  final EditorProvider provider;
  final BookPage? currentPage;

  const _EditorHeader({required this.provider, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Cópia local: um campo de widget não sofre promoção de tipo, então
    // `currentPage.id` depois de um `!= null` não compilaria.
    final page = currentPage;
    if (page == null) return const SizedBox(height: 24);

    final matches = provider.chapters.where((c) => c.id == provider.currentChapterId);
    final chapter = matches.isEmpty ? null : matches.first.title;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.editorMaxWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (chapter != null)
                      Text(
                        chapter,
                        style: theme.textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    AutosaveField(
                      key: ValueKey('title-${page.id}'),
                      initialValue: page.title,
                      onChanged: (value) => provider.renamePage(page.id, value),
                      style: theme.textTheme.headlineMedium,
                      // Sem moldura: o título da página é texto que se
                      // edita no lugar, não um formulário a preencher.
                      bare: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: WordCountReadout(count: provider.wordCount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A barra de formatação numa faixa própria, na cor de painel e com uma
/// linha de 1px em cima e embaixo. Solta sobre o fundo ela flutuava sem
/// pertencer a nada; numa faixa, fica claro que é a moldura da folha.
class _ToolbarBar extends StatelessWidget {
  final QuillController controller;
  final String? pageId;

  const _ToolbarBar({required this.controller, required this.pageId});

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaces.panel,
        border: Border(
          top: BorderSide(color: surfaces.hairline),
          bottom: BorderSide(color: surfaces.hairline),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.editorMaxWidth),
          child: Align(
            alignment: Alignment.centerLeft,
            child: EditorToolbar(
              key: ValueKey('toolbar-$pageId'),
              controller: controller,
            ),
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
    final surfaces = context.surfaces;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.editorMaxWidth + 112),
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          decoration: BoxDecoration(
            color: surfaces.card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusSurface),
            ),
            border: Border.all(color: surfaces.hairline),
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
              padding: const EdgeInsets.fromLTRB(48, 36, 48, 8),
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
