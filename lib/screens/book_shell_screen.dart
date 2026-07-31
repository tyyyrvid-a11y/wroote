import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/book_core_provider.dart';
import '../services/editor_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_surfaces.dart';
import '../widgets/counters.dart';
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
          child: AppScaffold(
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
                  VerticalDivider(width: 1, color: context.surfaces.hairline),
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
    final surfaces = context.surfaces;

    return Container(
      width: 240,
      color: surfaces.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Voltar para a biblioteca  (Ctrl+W)',
                  size: 16,
                  sound: UiSound.close,
                  onPressed: onClose,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      // O nome do livro é o topo da hierarquia: serifado e o
                      // maior texto desta coluna. Tudo abaixo dele — seções,
                      // capítulos, páginas — desce um degrau de cada vez.
                      bookTitle,
                      style: theme.textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: surfaces.hairline),
          const SizedBox(height: 8),
          _RailItem(
            icon: Icons.dashboard_outlined,
            label: 'Núcleo do livro',
            hint: 'Ctrl+1',
            selected: selected == 0,
            onTap: () => onSelect(0),
          ),
          _RailItem(
            icon: Icons.edit_outlined,
            label: 'Escrita',
            hint: 'Ctrl+2',
            selected: selected == 1,
            onTap: () => onSelect(1),
          ),
          const Spacer(),
          Divider(height: 1, color: surfaces.hairline),
          const _AutosaveFooter(),
        ],
      ),
    );
  }
}

/// Item da barra de navegação.
///
/// O estado ativo não é um bloco de cor: é um marcador de 2px encostado na
/// borda da coluna, o rótulo no acento e um fundo em opacidade baixa. Basta
/// para achar onde se está com o canto do olho, sem transformar a barra
/// lateral num painel de botões coloridos.
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

    return Hoverable(
      onTap: onTap,
      // O item selecionado não toca som ao passar o cursor: ele já é o
      // estado atual, não um destino.
      hoverSound: selected ? null : UiSound.hover,
      tapSound: null, // `onSelect` toca o som de troca de seção.
      builder: (context, hovered, pressed) {
        final foreground = selected ? surfaces.accentInk : theme.colorScheme.onSurface;
        return AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: selected
                ? surfaces.activeTint
                : hovered
                    ? surfaces.hoverTint
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: selected ? surfaces.accentInk : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: selected ? surfaces.accentInk : theme.iconTheme.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MonoText(
                hint,
                size: 10.5,
                color: selected
                    ? surfaces.accentInk.withValues(alpha: 0.8)
                    : theme.textTheme.labelSmall?.color,
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          Icon(Icons.check, size: 13, color: theme.textTheme.labelSmall?.color),
          const SizedBox(width: 7),
          Expanded(
            child: Text('Salvo automaticamente', style: theme.textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}
