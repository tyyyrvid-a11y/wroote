import 'package:flutter/material.dart';

import '../services/library_provider.dart';
import '../theme/app_surfaces.dart';
import 'surfaces.dart';

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

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  book.title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              _CardMenu(onRename: onRename, onDelete: onDelete),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.wordCount} palavra${entry.wordCount == 1 ? '' : 's'}'
            '${entry.pageEstimate > 0 ? ' · meta de ${entry.pageEstimate} páginas' : ''}',
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: GradientProgressBar(value: entry.progress)),
              const SizedBox(width: 10),
              Text(
                '$percent%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barra de progresso com o gradiente de acento e um trilho afundado.
///
/// Substitui o [LinearProgressIndicator], que pinta uma faixa de cor chapada
/// e não tem como receber gradiente sem gambiarra.
class GradientProgressBar extends StatelessWidget {
  final double value;
  final double height;

  const GradientProgressBar({super.key, required this.value, this.height = 7});

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.outline.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                // Horizontal aqui, e não vertical: numa faixa de 7px de
                // altura um gradiente vertical não teria espaço para
                // aparecer, enquanto o horizontal acompanha o avanço.
                gradient: LinearGradient(
                  colors: surfaces.accent.colors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
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
      icon: const Icon(Icons.more_horiz, size: 18),
      tooltip: 'Opções',
      splashRadius: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'rename') onRename();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'rename',
          height: 40,
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 16),
            SizedBox(width: 10),
            Text('Renomear'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 40,
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
