import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../services/sound_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import 'hoverable.dart';
import 'surfaces.dart';

/// Barra de formatação do editor.
///
/// Escrita à mão em vez de usar a `QuillSimpleToolbar`: a barra pronta
/// mistura ícones de tamanhos e pesos diferentes, botões com fundo colorido
/// e menus suspensos com a densidade do Material para toque. Aqui todo botão
/// tem o mesmo alvo (28×28), o mesmo glifo de 16px, e o único destaque é o
/// estado ativo — o acento sobre um fundo em opacidade baixa.
///
/// Os controles são agrupados por função (histórico · ênfase · nível de
/// título · blocos) e separados por linhas verticais de 1px.
class EditorToolbar extends StatelessWidget {
  final QuillController controller;

  const EditorToolbar({super.key, required this.controller});

  /// Liga/desliga um atributo na seleção. Desligar é aplicar o mesmo
  /// atributo com valor nulo — é assim que o Quill representa "sem".
  void _toggle(Attribute attribute, bool isActive) {
    controller.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
  }

  bool _isActive(Map<String, Attribute> attributes, Attribute attribute) {
    return attributes[attribute.key]?.value == attribute.value;
  }

  @override
  Widget build(BuildContext context) {
    // O controller notifica a cada mudança de seleção, então os estados
    // ativos acompanham o cursor enquanto a pessoa navega pelo texto.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final attributes = controller.getSelectionStyle().attributes;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarButton(
              icon: Icons.undo,
              tooltip: 'Desfazer  (Ctrl+Z)',
              onPressed: controller.hasUndo ? controller.undo : null,
            ),
            _ToolbarButton(
              icon: Icons.redo,
              tooltip: 'Refazer  (Ctrl+Y)',
              onPressed: controller.hasRedo ? controller.redo : null,
            ),
            const ToolbarSeparator(),
            _ToolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Negrito  (Ctrl+B)',
              active: _isActive(attributes, Attribute.bold),
              onPressed: () => _toggle(Attribute.bold, _isActive(attributes, Attribute.bold)),
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Itálico  (Ctrl+I)',
              active: _isActive(attributes, Attribute.italic),
              onPressed: () => _toggle(Attribute.italic, _isActive(attributes, Attribute.italic)),
            ),
            _ToolbarButton(
              icon: Icons.format_underlined,
              tooltip: 'Sublinhado  (Ctrl+U)',
              active: _isActive(attributes, Attribute.underline),
              onPressed: () =>
                  _toggle(Attribute.underline, _isActive(attributes, Attribute.underline)),
            ),
            _ToolbarButton(
              icon: Icons.format_strikethrough,
              tooltip: 'Riscado',
              active: _isActive(attributes, Attribute.strikeThrough),
              onPressed: () =>
                  _toggle(Attribute.strikeThrough, _isActive(attributes, Attribute.strikeThrough)),
            ),
            const ToolbarSeparator(),
            // Níveis de título como rótulo, não como ícone: "H1" diz o que
            // faz sem depender de convenção, e mantém a barra tipográfica.
            _ToolbarLabelButton(
              label: 'H1',
              tooltip: 'Título de capítulo',
              active: _isActive(attributes, Attribute.h1),
              onPressed: () => _toggle(Attribute.h1, _isActive(attributes, Attribute.h1)),
            ),
            _ToolbarLabelButton(
              label: 'H2',
              tooltip: 'Subtítulo',
              active: _isActive(attributes, Attribute.h2),
              onPressed: () => _toggle(Attribute.h2, _isActive(attributes, Attribute.h2)),
            ),
            const ToolbarSeparator(),
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'Lista',
              active: _isActive(attributes, Attribute.ul),
              onPressed: () => _toggle(Attribute.ul, _isActive(attributes, Attribute.ul)),
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: 'Lista numerada',
              active: _isActive(attributes, Attribute.ol),
              onPressed: () => _toggle(Attribute.ol, _isActive(attributes, Attribute.ol)),
            ),
            _ToolbarButton(
              icon: Icons.format_quote,
              tooltip: 'Citação',
              active: _isActive(attributes, Attribute.blockQuote),
              onPressed: () =>
                  _toggle(Attribute.blockQuote, _isActive(attributes, Attribute.blockQuote)),
            ),
          ],
        );
      },
    );
  }
}

/// Botão de ícone da barra. Mesmo alvo e mesmo glifo que os demais botões de
/// ícone do app — a barra do editor não é um componente à parte.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: icon,
      tooltip: tooltip,
      size: 16,
      active: active,
      onPressed: onPressed,
      sound: UiSound.toggle,
      // Doze botões colados: som só no clique.
      hoverSound: null,
    );
  }
}

/// Variante com rótulo de texto, para os níveis de título.
class _ToolbarLabelButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  const _ToolbarLabelButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = context.surfaces;

    return Hoverable(
      onTap: onPressed,
      tooltip: tooltip,
      tapSound: UiSound.toggle,
      hoverSound: null,
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? surfaces.activeTint
                : hovered
                    ? surfaces.hoverTint
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusTight),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 11.5,
              letterSpacing: 0.2,
              color: active ? surfaces.accentInk : theme.iconTheme.color,
            ),
          ),
        );
      },
    );
  }
}
