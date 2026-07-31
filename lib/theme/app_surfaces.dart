import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens de superfície do app, expostos como [ThemeExtension] para que
/// claro e escuro sejam interpolados junto com o resto do tema.
///
/// Aqui não existe gradiente nem sombra decorativa. A hierarquia entre
/// planos é dita por três coisas, nesta ordem: **cor chapada**, **linha de
/// 1px** e **espaçamento**. Sombra sobrou em um único lugar — [overlayShadow]
/// — porque um menu ou diálogo precisa se destacar da página que ele cobre.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  /// Fundo da janela.
  final Color canvas;

  /// Barras laterais, cabeçalhos e faixas de ferramentas.
  final Color panel;

  /// Superfícies de conteúdo: cartões, folha do editor.
  final Color card;
  final Color cardHover;

  /// Divisores e bordas de 1px.
  final Color hairline;

  /// Borda de 1px de um elemento sob o cursor ou em foco.
  final Color hairlineStrong;

  /// Acento legível como texto, ícone ou marcador.
  final Color accentInk;

  /// Acento como preenchimento, sempre com texto branco por cima.
  final Color accentFill;
  final Color accentFillHover;

  /// Fundo de um item ativo numa lista: o acento em opacidade baixa.
  final Color activeTint;

  /// Fundo de um item sob o cursor. Neutro de propósito — hover não é
  /// seleção, então não pode usar a cor de acento.
  final Color hoverTint;

  /// Sombra de elementos que flutuam sobre a página (diálogos, menus).
  final List<BoxShadow> overlayShadow;

  const AppSurfaces({
    required this.canvas,
    required this.panel,
    required this.card,
    required this.cardHover,
    required this.hairline,
    required this.hairlineStrong,
    required this.accentInk,
    required this.accentFill,
    required this.accentFillHover,
    required this.activeTint,
    required this.hoverTint,
    required this.overlayShadow,
  });

  factory AppSurfaces.of(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return AppSurfaces(
      canvas: isDark ? AppColors.graphiteCanvas : AppColors.paperCanvas,
      panel: isDark ? AppColors.graphitePanel : AppColors.paperPanel,
      card: isDark ? AppColors.graphiteCard : AppColors.paperCard,
      cardHover: isDark ? AppColors.graphiteCardHover : AppColors.paperCardHover,
      hairline: isDark ? AppColors.graphiteHairline : AppColors.paperHairline,
      hairlineStrong: isDark ? AppColors.graphiteHairlineStrong : AppColors.paperHairlineStrong,
      accentInk: isDark ? AppColors.accentOnDark : AppColors.accent,
      // No escuro o acento cheio afunda no grafite; o tom levantado mantém o
      // botão presente sem clarear a ponto de virar um bloco de cor.
      accentFill: isDark ? AppColors.accentRaised : AppColors.accent,
      accentFillHover: isDark ? const Color(0xFF3E828D) : AppColors.accentRaised,
      activeTint: isDark
          ? AppColors.accentOnDark.withValues(alpha: 0.10)
          : AppColors.accent.withValues(alpha: 0.09),
      hoverTint: isDark
          ? Colors.white.withValues(alpha: 0.045)
          : Colors.black.withValues(alpha: 0.035),
      overlayShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  @override
  AppSurfaces copyWith({
    Color? canvas,
    Color? panel,
    Color? card,
    Color? cardHover,
    Color? hairline,
    Color? hairlineStrong,
    Color? accentInk,
    Color? accentFill,
    Color? accentFillHover,
    Color? activeTint,
    Color? hoverTint,
    List<BoxShadow>? overlayShadow,
  }) {
    return AppSurfaces(
      canvas: canvas ?? this.canvas,
      panel: panel ?? this.panel,
      card: card ?? this.card,
      cardHover: cardHover ?? this.cardHover,
      hairline: hairline ?? this.hairline,
      hairlineStrong: hairlineStrong ?? this.hairlineStrong,
      accentInk: accentInk ?? this.accentInk,
      accentFill: accentFill ?? this.accentFill,
      accentFillHover: accentFillHover ?? this.accentFillHover,
      activeTint: activeTint ?? this.activeTint,
      hoverTint: hoverTint ?? this.hoverTint,
      overlayShadow: overlayShadow ?? this.overlayShadow,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineStrong: Color.lerp(hairlineStrong, other.hairlineStrong, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
      accentFillHover: Color.lerp(accentFillHover, other.accentFillHover, t)!,
      activeTint: Color.lerp(activeTint, other.activeTint, t)!,
      hoverTint: Color.lerp(hoverTint, other.hoverTint, t)!,
      overlayShadow: BoxShadow.lerpList(overlayShadow, other.overlayShadow, t)!,
    );
  }
}

extension AppSurfacesX on BuildContext {
  AppSurfaces get surfaces => Theme.of(this).extension<AppSurfaces>()!;
}
