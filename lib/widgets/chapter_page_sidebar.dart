import 'package:flutter/material.dart';

import '../models/chapter.dart';
import '../services/editor_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import 'confirm_dialog.dart';
import 'hoverable.dart';
import 'surfaces.dart';
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
      _refuse(context, 'O livro precisa ter ao menos um capítulo.');
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir "$title"?',
      message: 'Todas as páginas deste capítulo serão apagadas permanentemente.',
    );
    if (!confirmed || !context.mounted) return;
    provider.deleteChapter(chapterId);
    context.sounds.play(UiSound.delete);
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
      _refuse(context, 'O capítulo precisa ter ao menos uma página.');
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir "$title"?',
      message: 'O conteúdo desta página será apagado permanentemente.',
    );
    if (!confirmed || !context.mounted) return;
    provider.deletePage(pageId);
    context.sounds.play(UiSound.delete);
  }

  /// Recusa uma ação: aviso na tela e som de bloqueio. O som é o que faz a
  /// recusa ser percebida mesmo quando o olho está no outro canto da janela.
  void _refuse(BuildContext context, String message) {
    context.sounds.play(UiSound.blocked);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 250,
      decoration: BoxDecoration(gradient: context.surfaces.chrome),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
            child: Row(
              children: [
                Expanded(child: Text('Capítulos', style: theme.textTheme.titleSmall)),
                AppIconButton(
                  icon: Icons.post_add_outlined,
                  tooltip: 'Novo capítulo',
                  sound: UiSound.success,
                  onPressed: () => provider.addChapter(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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

  void _toggle() {
    setState(() => _expanded = !_expanded);
    context.sounds.play(UiSound.toggle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = widget.provider.pagesFor(widget.chapter.id);
    final isCurrentChapter = widget.chapter.id == widget.provider.currentChapterId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hoverable(
          onTap: _toggle,
          tapSound: null, // `_toggle` já toca o som de expandir/recolher.
          builder: (context, hovered, pressed) {
            return AnimatedContainer(
              duration: AppMotion.instant,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: hovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  // Uma seta que gira lê melhor que dois ícones distintos:
                  // a rotação mostra a transição, não só o estado final.
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: AppMotion.fast,
                    curve: AppMotion.enter,
                    child: Icon(Icons.chevron_right, size: 18, color: theme.iconTheme.color),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.chapter.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrentChapter ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrentChapter ? theme.colorScheme.primary : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _TileMenu(
                    onSelected: (value) {
                      if (value == 'rename') widget.onRename();
                      if (value == 'delete') widget.onDelete();
                      if (value == 'add_page') widget.provider.addPage(widget.chapter.id);
                    },
                    items: const [
                      ('add_page', Icons.note_add_outlined, 'Nova página', false),
                      ('rename', Icons.edit_outlined, 'Renomear capítulo', false),
                      ('delete', Icons.delete_outline, 'Excluir capítulo', true),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        // AnimatedSize dá à expansão uma transição contínua em vez de a
        // lista saltar de altura.
        AnimatedSize(
          duration: AppMotion.base,
          curve: AppMotion.enter,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Column(
                  children: [
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
                )
              : const SizedBox(width: double.infinity),
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

    return Padding(
      padding: const EdgeInsets.only(left: 18, top: 1, bottom: 1),
      child: Hoverable(
        onTap: onTap,
        hoverSound: isSelected ? null : UiSound.hover,
        tapSound: isSelected ? null : UiSound.page,
        builder: (context, hovered, pressed) {
          return AnimatedContainer(
            duration: AppMotion.instant,
            padding: const EdgeInsets.only(left: 10, right: 4, top: 7, bottom: 7),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.22),
                        theme.colorScheme.primary.withValues(alpha: 0.06),
                      ],
                    )
                  : null,
              color: !isSelected && hovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border(
                // Marcador de 2px na borda esquerda do item ativo — mais
                // legível numa lista densa do que só a mudança de fundo.
                left: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 15,
                  color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
                ),
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
                _TileMenu(
                  onSelected: (value) {
                    if (value == 'rename') onRename();
                    if (value == 'delete') onDelete();
                  },
                  items: const [
                    ('rename', Icons.edit_outlined, 'Renomear página', false),
                    ('delete', Icons.delete_outline, 'Excluir página', true),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Menu compacto reaproveitado pelos tiles de capítulo e de página.
///
/// Cada item é `(valor, ícone, rótulo, éDestrutivo)`; o destrutivo sai na
/// cor de erro para não ser clicado por engano numa lista densa.
class _TileMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;
  final List<(String, IconData, String, bool)> items;

  const _TileMenu({required this.onSelected, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 16),
      tooltip: 'Opções',
      padding: EdgeInsets.zero,
      splashRadius: 16,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 28),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final (value, icon, label, destructive) in items)
          PopupMenuItem(
            value: value,
            height: 38,
            child: Row(
              children: [
                Icon(icon, size: 15, color: destructive ? theme.colorScheme.error : null),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: destructive ? TextStyle(color: theme.colorScheme.error) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
