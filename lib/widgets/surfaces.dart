import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import 'hoverable.dart';

/// [Scaffold] que pinta o gradiente de fundo do app.
///
/// O gradiente fica atrás de tudo para que a janela inteira seja uma
/// superfície contínua, em vez de faixas de cor empilhadas. O [Scaffold]
/// por cima fica transparente e continua fornecendo o que interessa:
/// [ScaffoldMessenger] para as SnackBars e a camada de overlays.
class GradientScaffold extends StatelessWidget {
  final Widget body;

  const GradientScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.surfaces.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
      ),
    );
  }
}

/// Superfície elevada padrão: gradiente vertical, borda, sombra e a linha
/// de luz de 1px no topo.
///
/// Quando [onTap] é informado, o cartão ganha hover (sobe, clareia e a
/// sombra se espalha) e som; caso contrário é puramente decorativo.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final double radius;

  /// Deslocamento vertical no hover. Zero desliga a subida, mantendo só a
  /// mudança de cor — usado onde o cartão está dentro de uma lista rolável.
  final double hoverLift;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.onSecondaryTap,
    this.radius = AppTheme.radiusLarge,
    this.hoverLift = 3,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final border = Theme.of(context).colorScheme.outline;
    final borderRadius = BorderRadius.circular(radius);

    return Hoverable(
      onTap: onTap,
      onSecondaryTap: onSecondaryTap,
      // Cartões grandes com som de hover ficam cansativos; quem faz barulho
      // aqui é o clique.
      hoverSound: onTap == null ? null : UiSound.hover,
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          transform: Matrix4.translationValues(0, hovered ? -hoverLift : 0, 0),
          decoration: BoxDecoration(
            gradient: hovered ? surfaces.cardHovered : surfaces.card,
            borderRadius: borderRadius,
            border: Border.all(
              color: hovered
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.45)
                  : border,
            ),
            boxShadow: hovered ? surfaces.cardShadowHovered : surfaces.cardShadow,
          ),
          child: PressScale(
            pressed: pressed,
            child: _TopHighlight(
              radius: radius,
              color: surfaces.topHighlight,
              child: Padding(padding: padding, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// Desenha uma linha de luz de 1px acompanhando a borda superior
/// arredondada. É o detalhe que dá espessura à superfície.
class _TopHighlight extends StatelessWidget {
  final double radius;
  final Color color;
  final Widget child;

  const _TopHighlight({required this.radius, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _TopHighlightPainter(radius: radius, color: color),
      child: child,
    );
  }
}

class _TopHighlightPainter extends CustomPainter {
  final double radius;
  final Color color;

  _TopHighlightPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Meio pixel para dentro, senão a linha cai em cima da borda do
    // container e some.
    final r = radius - 0.5;
    final path = Path()
      ..moveTo(0.5, radius)
      ..arcToPoint(Offset(radius, 0.5), radius: Radius.circular(r))
      ..lineTo(size.width - radius, 0.5)
      ..arcToPoint(Offset(size.width - 0.5, radius), radius: Radius.circular(r));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TopHighlightPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Botão primário com gradiente de acento e sombra colorida.
class AccentButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final UiSound sound;

  const AccentButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.sound = UiSound.tap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final enabled = onPressed != null;
    final borderRadius = BorderRadius.circular(AppTheme.radiusMedium);

    return Hoverable(
      onTap: onPressed,
      tapSound: sound,
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: enabled ? surfaces.accent : null,
            color: enabled ? null : Theme.of(context).colorScheme.outline,
            borderRadius: borderRadius,
            boxShadow: enabled && hovered ? surfaces.accentShadow : const [],
          ),
          child: PressScale(
            pressed: pressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: kSansFontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Botão de ícone com hover, tooltip e som — o equivalente desktop do
/// [IconButton], que no Material tem área de toque de 48px e nenhum
/// feedback de cursor além do overlay padrão.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final UiSound sound;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 18,
    this.color,
    this.sound = UiSound.tap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hoverable(
      onTap: onPressed,
      tooltip: tooltip,
      tapSound: sound,
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: AppMotion.instant,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: hovered
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: PressScale(
            pressed: pressed,
            scale: 0.9,
            child: Icon(
              icon,
              size: size,
              color: onPressed == null
                  ? theme.disabledColor
                  : hovered
                      ? theme.colorScheme.primary
                      : (color ?? theme.iconTheme.color),
            ),
          ),
        );
      },
    );
  }
}

/// Centraliza e limita a largura do conteúdo.
///
/// A regra anti-"celular esticado": numa janela de 2560px, um formulário
/// que ocupa a largura toda é ilegível. O conteúdo para de crescer em
/// [maxWidth] e sobra respiro nas laterais.
class ContentColumn extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ContentColumn({
    super.key,
    required this.child,
    this.maxWidth = AppTheme.contentMaxWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
