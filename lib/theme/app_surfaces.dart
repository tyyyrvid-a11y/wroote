import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradientes e sombras do app, expostos como [ThemeExtension] para que
/// claro e escuro sejam interpolados junto com o resto do tema.
///
/// Existe uma convenção única por trás de tudo aqui: a luz vem de cima. Todo
/// gradiente vai do tom mais claro no topo para o mais escuro na base, toda
/// sombra cai para baixo, e superfícies elevadas ganham uma linha de luz de
/// 1px na borda superior. Seguir isso à risca é o que diferencia "tem
/// profundidade" de "tem gradiente".
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  /// Fundo da janela. Aplicado uma vez, no [Scaffold] raiz de cada tela.
  final LinearGradient background;

  /// Superfície de cartões e painéis elevados.
  final LinearGradient card;

  /// Cartão sob o cursor. Mais claro e com um pouco mais de contraste.
  final LinearGradient cardHovered;

  /// Barras laterais e topo: mais discreto que um cartão, para não competir
  /// com o conteúdo.
  final LinearGradient chrome;

  /// Botões primários e outros elementos de acento.
  final LinearGradient accent;

  /// Linha de luz no topo de superfícies elevadas.
  final Color topHighlight;

  /// Sombra de repouso de um cartão.
  final List<BoxShadow> cardShadow;

  /// Sombra de um cartão sob o cursor: mais alta e mais espalhada, como se
  /// o cartão tivesse subido em direção à luz.
  final List<BoxShadow> cardShadowHovered;

  /// Sombra de elementos flutuantes (diálogos, menus, barra de comando).
  final List<BoxShadow> overlayShadow;

  /// Sombra colorida sob botões primários — herda o matiz do acento em vez
  /// de um cinza neutro, que é o que faz o botão parecer emitir luz.
  final List<BoxShadow> accentShadow;

  const AppSurfaces({
    required this.background,
    required this.card,
    required this.cardHovered,
    required this.chrome,
    required this.accent,
    required this.topHighlight,
    required this.cardShadow,
    required this.cardShadowHovered,
    required this.overlayShadow,
    required this.accentShadow,
  });

  factory AppSurfaces.of(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // No escuro, sombras precisam ser bem mais opacas para aparecer sobre um
    // fundo já escuro; no claro, o mesmo valor viraria uma mancha suja.
    final shadowColor = isDark ? Colors.black : const Color(0xFF6B5B45);
    double alpha(double light, double dark) => isDark ? dark : light;

    return AppSurfaces(
      background: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [AppColors.duskBackgroundTop, AppColors.duskBackgroundBottom]
            : const [AppColors.creamBackgroundTop, AppColors.creamBackgroundBottom],
      ),
      card: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [AppColors.duskCardTop, AppColors.duskCardBottom]
            : const [AppColors.creamCardTop, AppColors.creamCardBottom],
      ),
      cardHovered: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF3A3630), AppColors.duskCardTop]
            : const [Colors.white, Color(0xFFFDFBF7)],
      ),
      chrome: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF2B2721), Color(0xFF211E19)]
            : const [Color(0xFFF9F6F0), Color(0xFFF2EDE4)],
      ),
      accent: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.terracottaLight, AppColors.terracottaDeep],
      ),
      topHighlight: isDark ? AppColors.highlightDark : AppColors.highlightLight,
      cardShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: alpha(0.06, 0.28)),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
      cardShadowHovered: [
        BoxShadow(
          color: shadowColor.withValues(alpha: alpha(0.12, 0.40)),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      overlayShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: alpha(0.18, 0.50)),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ],
      accentShadow: [
        BoxShadow(
          color: AppColors.terracotta.withValues(alpha: alpha(0.35, 0.30)),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  @override
  AppSurfaces copyWith({
    LinearGradient? background,
    LinearGradient? card,
    LinearGradient? cardHovered,
    LinearGradient? chrome,
    LinearGradient? accent,
    Color? topHighlight,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? cardShadowHovered,
    List<BoxShadow>? overlayShadow,
    List<BoxShadow>? accentShadow,
  }) {
    return AppSurfaces(
      background: background ?? this.background,
      card: card ?? this.card,
      cardHovered: cardHovered ?? this.cardHovered,
      chrome: chrome ?? this.chrome,
      accent: accent ?? this.accent,
      topHighlight: topHighlight ?? this.topHighlight,
      cardShadow: cardShadow ?? this.cardShadow,
      cardShadowHovered: cardShadowHovered ?? this.cardShadowHovered,
      overlayShadow: overlayShadow ?? this.overlayShadow,
      accentShadow: accentShadow ?? this.accentShadow,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      background: LinearGradient.lerp(background, other.background, t)!,
      card: LinearGradient.lerp(card, other.card, t)!,
      cardHovered: LinearGradient.lerp(cardHovered, other.cardHovered, t)!,
      chrome: LinearGradient.lerp(chrome, other.chrome, t)!,
      accent: LinearGradient.lerp(accent, other.accent, t)!,
      topHighlight: Color.lerp(topHighlight, other.topHighlight, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      cardShadowHovered: BoxShadow.lerpList(cardShadowHovered, other.cardShadowHovered, t)!,
      overlayShadow: BoxShadow.lerpList(overlayShadow, other.overlayShadow, t)!,
      accentShadow: BoxShadow.lerpList(accentShadow, other.accentShadow, t)!,
    );
  }
}

extension AppSurfacesX on BuildContext {
  AppSurfaces get surfaces => Theme.of(this).extension<AppSurfaces>()!;
}
