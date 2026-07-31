import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import 'hoverable.dart';

/// [Scaffold] com o fundo chapado do app.
///
/// O [Scaffold] por cima fica transparente e continua fornecendo o que
/// interessa: [ScaffoldMessenger] para as SnackBars e a camada de overlays.
class AppScaffold extends StatelessWidget {
  final Widget body;

  const AppScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.surfaces.canvas,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
      ),
    );
  }
}

/// Superfície de conteúdo: cor chapada e uma borda de 1px. Sem sombra, sem
/// elevação, sem subir no hover.
///
/// A separação entre um cartão e o fundo vem do par cor + linha; a separação
/// entre um cartão e o outro vem do espaço entre eles. Sombra aqui seria
/// decoração pura — e é o que faz uma grade de cartões parecer uma tela de
/// dashboard em vez de uma lista de arquivos.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.onSecondaryTap,
    this.radius = AppTheme.radiusSurface,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final borderRadius = BorderRadius.circular(radius);
    final interactive = onTap != null || onSecondaryTap != null;

    return Hoverable(
      onTap: onTap,
      onSecondaryTap: onSecondaryTap,
      // Cartões grandes com som de hover ficam cansativos; quem faz barulho
      // aqui é o clique.
      hoverSound: null,
      builder: (context, hovered, pressed) {
        final active = interactive && (hovered || pressed);
        return AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          decoration: BoxDecoration(
            color: active ? surfaces.cardHover : surfaces.card,
            borderRadius: borderRadius,
            border: Border.all(
              color: active ? surfaces.hairlineStrong : surfaces.hairline,
            ),
          ),
          child: Padding(padding: padding, child: child),
        );
      },
    );
  }
}

/// Ação primária: retângulo de cantos levemente arredondados, preenchido com
/// o acento, ancorado no fluxo do layout. Um por tela, no máximo.
///
/// Com [destructive], troca o acento pela cor de erro — é o único outro
/// preenchimento colorido que existe no app.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// `null` silencia o clique — para quando a ação que se segue toca o
  /// próprio som e dois efeitos colados viram um borrão.
  final UiSound? sound;
  final bool destructive;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.sound = UiSound.tap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = context.surfaces;
    final enabled = onPressed != null;

    final base = destructive ? theme.colorScheme.error : surfaces.accentFill;
    final raised = destructive
        ? Color.lerp(theme.colorScheme.error, Colors.white, 0.12)!
        : surfaces.accentFillHover;

    return Hoverable(
      onTap: onPressed,
      tapSound: sound,
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: icon == null ? 16 : 12),
          decoration: BoxDecoration(
            color: !enabled
                ? surfaces.hairline
                : pressed
                    ? base
                    : hovered
                        ? raised
                        : base,
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: Colors.white),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: enabled ? Colors.white : theme.disabledColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Botão secundário: só contorno. Usado onde a ação existe mas não é o que
/// se espera que a pessoa faça.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final UiSound? sound;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.sound = UiSound.tap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = context.surfaces;

    return Hoverable(
      onTap: onPressed,
      tapSound: sound,
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hovered ? surfaces.hoverTint : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            border: Border.all(
              color: hovered ? surfaces.hairlineStrong : surfaces.hairline,
            ),
          ),
          child: Text(label, style: theme.textTheme.labelLarge),
        );
      },
    );
  }
}

/// Botão de ícone da interface. Todos têm o mesmo tamanho de alvo (28×28) e
/// o mesmo tamanho de glifo, independentemente de onde apareçam.
///
/// O estado ativo tinge o ícone com o acento e o fundo com o acento em
/// opacidade baixa — nunca um preenchimento cheio de cor.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final UiSound sound;

  /// Som ao passar o cursor. A barra do editor passa `null`: doze ícones
  /// lado a lado tocando a cada centímetro de mouse viram ruído.
  final UiSound? hoverSound;

  /// Estado ligado/selecionado — usado pela barra do editor.
  final bool active;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 17,
    this.color,
    this.sound = UiSound.tap,
    this.hoverSound = UiSound.hover,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = context.surfaces;
    final enabled = onPressed != null;

    return Hoverable(
      onTap: onPressed,
      tooltip: tooltip,
      tapSound: sound,
      hoverSound: hoverSound,
      builder: (context, hovered, pressed) {
        final Color iconColor;
        if (!enabled) {
          iconColor = theme.disabledColor;
        } else if (active) {
          iconColor = surfaces.accentInk;
        } else if (hovered) {
          iconColor = theme.colorScheme.onSurface;
        } else {
          iconColor = color ?? theme.iconTheme.color!;
        }

        return AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.enter,
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? surfaces.activeTint
                : (hovered && enabled)
                    ? surfaces.hoverTint
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusTight),
          ),
          child: Icon(icon, size: size, color: iconColor),
        );
      },
    );
  }
}

/// Separador vertical de 1px para agrupar controles numa barra.
class ToolbarSeparator extends StatelessWidget {
  final double height;

  const ToolbarSeparator({super.key, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      color: context.surfaces.hairline,
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
