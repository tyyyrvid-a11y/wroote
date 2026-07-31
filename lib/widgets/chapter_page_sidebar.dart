import 'package:flutter/material.dart';

import '../models/chapter.dart';
import '../services/editor_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_surfaces.dart';
import 'confirm_dialog.dart';
import 'counters.dart';
import 'hoverable.dart';
import 'surfaces.dart';
import 'text_prompt_dialog.dart';

/// Navegação em árvore entre capítulos e páginas, usada na tela de escrita.
///
/// Os grupos são separados por linhas de 1px, não por blocos de fundo
/// cinza: numa lista de vinte capítulos, vinte blocos preenchidos viram uma
/// escada de retângulos, e o texto — que é o conteúdo real — some no meio.
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
    final surfaces = context.surfaces;
    final chapters = provider.chapters;

    return Container(
      width: 258,
      color: surfaces.panel,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Expanded(child: Text('CAPÍTULOS', style: theme.textTheme.titleSmall)),
                MonoText(
                  '${chapters.length}',
                  size: 10.5,
                  color: theme.textTheme.labelSmall?.color,
                ),
                const SizedBox(width: 8),
                AppIconButton(
                  icon: Icons.add,
                  tooltip: 'Novo capítulo',
                  size: 16,
                  sound: UiSound.success,
                  onPressed: () => provider.addChapter(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: surfaces.hairline),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final chapter in chapters)
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
    final surfaces = context.surfaces;
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
              curve: AppMotion.enter,
              padding: const EdgeInsets.fromLTRB(8, 9, 6, 9),
              color: hovered ? surfaces.hoverTint : Colors.transparent,
              child: Row(
                children: [
                  // Uma seta que gira lê melhor que dois ícones distintos:
                  // a rotação mostra a transição, não só o estado final.
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: AppMotion.fast,
                    curve: AppMotion.enter,
                    child: Icon(Icons.chevron_right, size: 16, color: theme.iconTheme.color),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      // Serifado, como o nome do livro — é um nome que o
                      // autor escreveu. Um degrau abaixo dele em tamanho, e
                      // um degrau acima do nome da página.
                      widget.chapter.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 14,
                        height: 1.3,
                        color: isCurrentChapter
                            ? theme.colorScheme.onSurface
                            : theme.textTheme.bodySmall?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _TileMenu(
                    onSelected: (value) {
                      if (value == 'rename') widget.onRename();
                      if (value == 'delete') widget.onDelete();
                      if (value == 'add_page') widget.provider.addPage(widget.chapter.id);
                    },
                    items: const [
                      ('add_page', Icons.add, 'Nova página', false),
                      ('rename', Icons.drive_file_rename_outline, 'Renomear capítulo', false),
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
                    _AddPageTile(onTap: () => widget.provider.addPage(widget.chapter.id)),
                    const SizedBox(height: 4),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
        Divider(height: 1, color: surfaces.hairline),
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
    final surfaces = context.surfaces;

    return Hoverable(
      onTap: onTap,
      hoverSound: isSelected ? null : UiSound.hover,
      tapSound: isSelected ? null : UiSound.page,
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          padding: const EdgeInsets.fromLTRB(26, 6, 6, 6),
          decoration: BoxDecoration(
            color: isSelected
                ? surfaces.activeTint
                : hovered
                    ? surfaces.hoverTint
                    : Colors.transparent,
            border: Border(
              // Marcador de 2px encostado na borda da coluna. Numa lista
              // densa ele é mais legível que qualquer mudança de fundo.
              left: BorderSide(
                color: isSelected ? surfaces.accentInk : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 14,
                color: isSelected ? surfaces.accentInk : theme.textTheme.labelSmall?.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  // Nome de arquivo: sans, tamanho de UI, peso normal. É o
                  // degrau mais baixo da hierarquia de nomes.
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12.5,
                    color: isSelected ? surfaces.accentInk : theme.textTheme.bodySmall?.color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              _TileMenu(
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                },
                items: const [
                  ('rename', Icons.drive_file_rename_outline, 'Renomear página', false),
                  ('delete', Icons.delete_outline, 'Excluir página', true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Última linha de cada capítulo: cria uma página ali dentro.
///
/// Criar página estava só no menu "…" do capítulo, enquanto criar capítulo
/// tinha um "+" visível no topo da coluna — a assimetria fazia parecer que
/// páginas não podiam ser criadas. A ação mora no fim da lista de páginas
/// porque é exatamente onde a nova página vai aparecer.
class _AddPageTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPageTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = context.surfaces;
    final faint = theme.textTheme.labelSmall?.color;

    return Hoverable(
      onTap: onTap,
      tapSound: UiSound.success,
      builder: (context, hovered, pressed) {
        final foreground = hovered ? theme.colorScheme.onSurface : faint;
        return AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          padding: const EdgeInsets.fromLTRB(26, 6, 6, 6),
          decoration: BoxDecoration(
            color: hovered ? surfaces.hoverTint : Colors.transparent,
            border: const Border(left: BorderSide(color: Colors.transparent, width: 2)),
          ),
          child: Row(
            children: [
              Icon(Icons.add, size: 14, color: foreground),
              const SizedBox(width: 8),
              Text(
                'Nova página',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12.5,
                  color: foreground,
                ),
              ),
            ],
          ),
        );
      },
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
      icon: const Icon(Icons.more_horiz, size: 15),
      tooltip: 'Opções',
      padding: EdgeInsets.zero,
      iconSize: 15,
      constraints: const BoxConstraints(minWidth: 180),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final (value, icon, label, destructive) in items)
          PopupMenuItem(
            value: value,
            height: 34,
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
