import 'package:flutter/material.dart';

import '../services/library_provider.dart';
import 'counters.dart';
import 'surfaces.dart';

/// Cartão de um livro na biblioteca.
///
/// A hierarquia dentro do cartão é a mesma do app inteiro: o nome do livro é
/// o único elemento serifado e o único em peso alto; tudo abaixo dele é
/// medida, e medida é mono e apagada.
class BookCard extends StatelessWidget {
  final BookWithProgress entry;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const BookCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = entry.book;
    final percent = (entry.progress * 100).round();
    final faint = theme.textTheme.labelSmall?.color;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    book.title,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _CardMenu(onRename: onRename, onDelete: onDelete),
            ],
          ),
          const SizedBox(height: 6),
          MonoText(
            '${formatCount(entry.wordCount)} ${entry.wordCount == 1 ? 'palavra' : 'palavras'}'
            '${entry.pageEstimate > 0 ? '  ·  meta ${entry.pageEstimate} pág.' : ''}',
            size: 11,
            color: faint,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(child: ProgressLine(value: entry.progress)),
                const SizedBox(width: 10),
                MonoText('$percent%', size: 11, color: faint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu de opções do cartão. O botão vence o `onTap` do cartão na arena de
/// gestos por ser o alvo mais interno, então clicar aqui abre o menu em vez
/// de abrir o livro.
class _CardMenu extends StatelessWidget {
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _CardMenu({required this.onRename, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 17),
      tooltip: 'Opções',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 160),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'rename') onRename();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'rename',
          height: 34,
          child: Row(children: [
            Icon(Icons.drive_file_rename_outline, size: 16),
            SizedBox(width: 10),
            Text('Renomear'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 34,
          child: Row(children: [
            Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Text('Excluir', style: TextStyle(color: theme.colorScheme.error)),
          ]),
        ),
      ],
    );
  }
}
