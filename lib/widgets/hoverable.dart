import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/app_motion.dart';

/// Envolve qualquer conteúdo com o trio que todo elemento clicável de
/// desktop precisa ter: cursor de mão, estado de hover e estado de pressão —
/// mais o som correspondente a cada um.
///
/// Existe porque `InkWell` foi desenhado para toque: o ripple conta a
/// história de um dedo que encostou, e o hover dele é um overlay cinza fixo.
/// No desktop o cursor está sobre o elemento *antes* do clique, então o
/// hover é o feedback principal e precisa ser desenhado pelo próprio widget.
class Hoverable extends StatefulWidget {
  /// Recebe o estado atual e devolve a aparência correspondente.
  final Widget Function(BuildContext context, bool hovered, bool pressed) builder;

  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;

  /// Som do clique. `null` silencia (útil quando a ação já toca o seu
  /// próprio som, para não sobrepor dois efeitos).
  final UiSound? tapSound;

  /// Som ao entrar com o cursor. Desligue em listas muito densas.
  final UiSound? hoverSound;

  final String? tooltip;

  const Hoverable({
    super.key,
    required this.builder,
    this.onTap,
    this.onSecondaryTap,
    this.tapSound = UiSound.tap,
    this.hoverSound = UiSound.hover,
    this.tooltip,
  });

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onSecondaryTap != null;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    if (value && widget.hoverSound != null) {
      context.sounds.play(widget.hoverSound!);
    }
  }

  void _handleTap() {
    if (widget.tapSound != null) context.sounds.play(widget.tapSound!);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.builder(context, _hovered && _enabled, _pressed && _enabled);

    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHovered(true),
      onExit: (_) {
        _setHovered(false);
        if (_pressed) setState(() => _pressed = false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? _handleTap : null,
        onSecondaryTap: widget.onSecondaryTap,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        child: child,
      ),
    );
  }
}

/// Escala sutil aplicada ao pressionar. 0.98 é o limite do perceptível — o
/// suficiente para o clique responder, longe do "botão de brinquedo".
class PressScale extends StatelessWidget {
  final bool pressed;
  final Widget child;
  final double scale;

  const PressScale({
    super.key,
    required this.pressed,
    required this.child,
    this.scale = 0.98,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? scale : 1,
      duration: AppMotion.instant,
      curve: AppMotion.enter,
      child: child,
    );
  }
}
