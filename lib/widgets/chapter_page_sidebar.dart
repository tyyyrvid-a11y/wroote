import 'package:flutter/material.dart';

import '../models/chapter.dart';
import '../services/editor_provider.dart';
import '../theme/app_theme.dart';
import 'confirm_dialog.dart';
import 'text_prompt_dialog.dart';

/// Navegação em árvore entre capítulos e páginas, usada na tela de escrita.
class ChapterPageSidebar extends StatelessWidget {
  final EditorProvider provider;

  const ChapterPageSidebar({super.key, required this.provider});

  Future<void> _renameChapter(BuildContext context, String chapterId, String currentTitle) async {
    final title = await TextPromptDialog.show(
      context,
      title: 'Renomear capítulo',
      label: 'Título do capítulo',
      initialValue: currentTitle,
      confirmLabel: 'Renomear',
    );
    if (title != null) provider.renameChapter(chapterId, title);
  }

  Future<void> _deleteChapter(BuildContext context, String chapterId, String title) async {
    if (provider.chapters.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O livro precisa ter ao menos um capítulo.')),
      );
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir "$title"?',
      message: 'Todas as páginas deste capítulo serão apagadas permanentemente.',
    );
    if (confirmed) provider.deleteChapter(chapterId);
  }

  Future<void> _renamePage(BuildContext context, String pageId, String currentTitle) async {
    final title = await TextPromptDialog.show(
      context,
      title: 'Renomear página',
      label: 'Título da página',
      initialValue: currentTitle,
      confirmLabel: 'Renomear',
    );
    if (title != null) provider.renamePage(pageId, title);
  }

  Future<void> _deletePage(BuildContext context, String pageId, String title, int pagesInChapter) async {
    if (pagesInChapter <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O capítulo precisa ter ao menos uma página.')),
      );
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir "$title"?',
      message: 'O conteúdo desta página será apagado permanentemente.',
    );
    if (confirmed) provider.deletePage(pageId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return Container(
      width: 268,
      color: semantic.surfaceRaised,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Expanded(child: Text('Capítulos', style: theme.textTheme.titleMedium)),
                IconButton(
                  tooltip: 'Novo capítulo',
                  icon: const Icon(Icons.post_add_outlined, size: 20),
                  onPressed: () => provider.addChapter(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final chapter in provider.chapters)
                  _ChapterTile(
                    key: ValueKey(chapter.id),
                    chapter: chapter,
                    provider: provider,
                    onRename: () => _renameChapter(context, chapter.id, chapter.title),
                    onDelete: () => _deleteChapter(context, chapter.id, chapter.title),
                    onRenamePage: (pageId, title) => _renamePage(context, pageId, title),
                    onDeletePage: (pageId, title, count) => _deletePage(context, pageId, title, count),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatefulWidget {
  final Chapter chapter;
  final EditorProvider provider;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final void Function(String pageId, String title) onRenamePage;
  final void Function(String pageId, String title, int pagesInChapter) onDeletePage;

  const _ChapterTile({
    super.key,
    required this.chapter,
    required this.provider,
    required this.onRename,
    required this.onDelete,
    required this.onRenamePage,
    required this.onDeletePage,
  });

  @override
  State<_ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<_ChapterTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = widget.provider.pagesFor(widget.chapter.id);
    final isCurrentChapter = widget.chapter.id == widget.provider.currentChapterId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(_expanded ? Icons.expand_more : Icons.chevron_right, size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.chapter.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrentChapter ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) {
                    if (value == 'rename') widget.onRename();
                    if (value == 'delete') widget.onDelete();
                    if (value == 'add_page') widget.provider.addPage(widget.chapter.id);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'add_page', child: Text('Nova página')),
                    PopupMenuItem(value: 'rename', child: Text('Renomear capítulo')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir capítulo')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          for (final page in pages)
            _PageTile(
              key: ValueKey(page.id),
              title: page.title,
              isSelected: page.id == widget.provider.currentPageId,
              onTap: () => widget.provider.openPage(page.id),
              onRename: () => widget.onRenamePage(page.id, page.title),
              onDelete: () => widget.onDeletePage(page.id, page.title, pages.length),
            ),
      ],
    );
  }
}

class _PageTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PageTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 40, right: 8, top: 8, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 16, color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? theme.colorScheme.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 16),
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Renomear página')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir página')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
