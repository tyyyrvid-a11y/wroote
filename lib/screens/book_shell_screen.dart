import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/book_core_provider.dart';
import '../services/editor_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import '../widgets/hoverable.dart';
import '../widgets/surfaces.dart';
import 'book_core_screen.dart';
import 'page_editor_screen.dart';

/// Contêiner de um livro aberto: alterna entre o Núcleo do Livro
/// (planejamento) e a Escrita de páginas, mantendo os dois providers
/// vivos enquanto o livro estiver aberto.
///
/// A navegação é uma barra lateral, não abas: abas com ícone e rótulo
/// empilhados são um padrão de celular: comem altura vertical (que no
/// desktop é o recurso escasso) e ficam perdidas no meio de uma janela larga.
class BookShellScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  const BookShellScreen({super.key, required this.bookId, required this.bookTitle});

  @override
  State<BookShellScreen> createState() => _BookShellScreenState();
}

class _BookShellScreenState extends State<BookShellScreen> {
  int _section = 0;

  void _goTo(int index) {
    if (_section == index) return;
    setState(() => _section = index);
    context.sounds.play(UiSound.page);
  }

  void _close() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookCoreProvider(widget.bookId)),
        ChangeNotifierProvider(create: (_) => EditorProvider(widget.bookId)),
      ],
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => _goTo(0),
          const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => _goTo(1),
          const SingleActivator(LogicalKeyboardKey.keyW, control: true): _close,
        },
        child: Focus(
          autofocus: true,
          child: GradientScaffold(
            body: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BookNavRail(
                    bookTitle: widget.bookTitle,
                    selected: _section,
                    onSelect: _goTo,
                    onClose: _close,
                  ),
                  VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outline),
                  // IndexedStack em vez de trocar o filho: mantém o editor
                  // Quill montado ao ir para o planejamento e voltar, o que
                  // preserva rolagem, cursor e histórico de desfazer.
                  Expanded(
                    child: IndexedStack(
                      index: _section,
                      children: const [BookCoreScreen(), PageEditorScreen()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookNavRail extends StatelessWidget {
  final String bookTitle;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  const _BookNavRail({
    required this.bookTitle,
    required this.selected,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 236,
      decoration: BoxDecoration(gradient: context.surfaces.chrome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            child: Row(
              children: [
                AppIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Voltar para a biblioteca  (Ctrl+W)',
                  size: 18,
                  sound: UiSound.close,
                  onPressed: onClose,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    bookTitle,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          _RailItem(
            icon: Icons.map_outlined,
            label: 'Núcleo do livro',
            hint: 'Ctrl+1',
            selected: selected == 0,
            onTap: () => onSelect(0),
          ),
          _RailItem(
            icon: Icons.edit_note_outlined,
            label: 'Escrita',
            hint: 'Ctrl+2',
            selected: selected == 1,
            onTap: () => onSelect(1),
          ),
          const Spacer(),
          const _AutosaveFooter(),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = context.surfaces;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Hoverable(
        onTap: onTap,
        // O item selecionado não toca som ao passar o cursor: ele já é o
        // estado atual, não um destino.
        hoverSound: selected ? null : UiSound.hover,
        tapSound: null, // `onSelect` toca o som de troca de seção.
        builder: (context, hovered, pressed) {
          return AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.enter,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? surfaces.accent : null,
              color: !selected && hovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              boxShadow: selected ? surfaces.accentShadow : const [],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? Colors.white : theme.iconTheme.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  hint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.75)
                        : theme.textTheme.labelSmall?.color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Aviso de autosave no rodapé da barra lateral. Estava no topo do Núcleo do
/// Livro, ocupando a primeira linha da tela para dizer algo que vale para o
/// app inteiro e que o usuário só quer conferir de vez em quando.
class _AutosaveFooter extends StatelessWidget {
  const _AutosaveFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Icon(Icons.cloud_done_outlined, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Salvo automaticamente', style: theme.textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}
