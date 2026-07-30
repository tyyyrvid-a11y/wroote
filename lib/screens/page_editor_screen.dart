import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import '../services/editor_provider.dart';
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

    final semantic = context.semanticColors;
    final currentPage = provider.currentPage;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChapterPageSidebar(provider: provider),
        VerticalDivider(width: 1, color: semantic.border),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: currentPage == null
                          ? const SizedBox.shrink()
                          : AutosaveField(
                              key: ValueKey('title-${currentPage.id}'),
                              initialValue: currentPage.title,
                              onChanged: (value) => provider.renamePage(currentPage.id, value),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                    ),
                    const SizedBox(width: 12),
                    WordCountBadge(count: provider.wordCount),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuillSimpleToolbar(
                  key: ValueKey('toolbar-${currentPage?.id}'),
                  controller: provider.controller,
                  config: const QuillSimpleToolbarConfig(),
                ),
              ),
              const SizedBox(height: 4),
              Divider(height: 1, color: semantic.border),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final serifBody = AppTheme.editorBodyStyle(context);
                    return Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.copyWith(
                              bodyLarge: serifBody,
                              bodyMedium: serifBody,
                              bodySmall: serifBody.copyWith(fontSize: 14),
                            ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: QuillEditor.basic(
                          key: ValueKey('editor-${currentPage?.id}'),
                          controller: provider.controller,
                          config: const QuillEditorConfig(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            placeholder: 'Comece a escrever…',
                            scrollable: true,
                            expands: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
