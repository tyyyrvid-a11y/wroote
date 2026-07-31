import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_surfaces.dart';

/// Três famílias, três papéis, sem sobreposição:
///
/// * **Serifada** — nomes de coisas que o autor escreveu: o livro, o
///   capítulo, a página, e o corpo do texto no editor.
/// * **Sans** — a interface inteira: rótulos, botões, campos, menus.
/// * **Mono** — só números que mudam: contagem de palavras, progresso,
///   atalhos de teclado.
///
/// A regra fecha a hierarquia sem depender de tamanho: mesmo em 13px, um
/// nome de capítulo se distingue de um rótulo de UI pelo desenho da letra.
const String kSerifFontFamily = 'Anthropic Serif';
const String kSansFontFamily = 'Source Sans 3';

/// Mono do sistema, em cascata. O app não empacota uma mono própria porque
/// ela aparece em contadores de duas ou três palavras — não vale 400kB por
/// plataforma. Se nenhuma existir, a cascata cai na fonte padrão e as
/// [FontFeature.tabularFigures] ainda mantêm os dígitos alinhados.
const String kMonoFontFamily = 'Consolas';
const List<String> kMonoFontFallback = [
  'SF Mono',
  'Menlo',
  'DejaVu Sans Mono',
  'Liberation Mono',
  'Courier New',
  'monospace',
];

class AppTheme {
  AppTheme._();

  // Raios. A escala inteira cabe entre 3 e 6px: o suficiente para tirar o
  // aspecto de caixa de diálogo do Windows 95, longe do arredondado de app
  // de celular.

  /// Estados de hover, marcadores, chips.
  static const double radiusTight = 3;

  /// Botões, campos, menus.
  static const double radiusControl = 5;

  /// Cartões, diálogos, a folha do editor.
  static const double radiusSurface = 6;

  /// Largura máxima de uma coluna de leitura/formulário. Numa tela de 27",
  /// deixar um campo de texto ocupar 2000px de largura é o erro mais comum
  /// de UI "de celular esticada" — nada aqui deve ultrapassar isso.
  static const double contentMaxWidth = 1180;

  /// Largura da coluna de escrita no editor. Mais estreita que
  /// [contentMaxWidth] porque texto corrido pede ~70 caracteres por linha.
  static const double editorMaxWidth = 760;

  /// Estilo usado para o corpo do texto no editor de páginas.
  static TextStyle editorBodyStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: kSerifFontFamily,
      fontSize: 17.5,
      height: 1.7,
      letterSpacing: 0.05,
      color: isDark ? AppColors.inkOnDark : AppColors.inkOnLight,
    );
  }

  /// Estilo dos contadores. Dígitos tabulares para o número não "pular"
  /// de largura a cada tecla digitada.
  static TextStyle mono(
    BuildContext context, {
    double size = 11.5,
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: kMonoFontFamily,
      fontFamilyFallback: kMonoFontFallback,
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
      letterSpacing: 0,
      color: color ?? Theme.of(context).textTheme.bodySmall?.color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static ThemeData get light => _buildTheme(brightness: Brightness.light);
  static ThemeData get dark => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final surfaces = AppSurfaces.of(brightness);

    final ink = isDark ? AppColors.inkOnDark : AppColors.inkOnLight;
    final inkSecondary = isDark ? AppColors.inkOnDarkSecondary : AppColors.inkOnLightSecondary;
    final inkFaint = isDark ? AppColors.inkOnDarkFaint : AppColors.inkOnLightFaint;
    final danger = isDark ? AppColors.dangerDark : AppColors.dangerLight;

    // Parte de um ColorScheme.fromSeed (que preenche todos os tons
    // derivados do Material 3) e sobrescreve só o que importa para a
    // identidade visual do Wroote, evitando ter que declarar manualmente
    // cada um dos ~30 campos do ColorScheme.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
    ).copyWith(
      primary: surfaces.accentFill,
      onPrimary: Colors.white,
      secondary: surfaces.accentInk,
      onSecondary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: surfaces.canvas,
      onSurface: ink,
      surfaceContainerHighest: surfaces.card,
      outline: surfaces.hairline,
      outlineVariant: surfaces.hairlineStrong,
    );

    TextStyle serif(double size, FontWeight weight, {Color? color, double tracking = -0.15}) {
      return TextStyle(
        fontFamily: kSerifFontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        letterSpacing: tracking,
        height: 1.25,
      );
    }

    TextStyle sans(
      double size,
      FontWeight weight, {
      Color? color,
      double tracking = 0,
      double height = 1.45,
    }) {
      return TextStyle(
        fontFamily: kSansFontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        // Source Sans 3 vem com espacejamento pensado para texto corrido;
        // em rótulos pequenos de UI ela fecha demais, então os tamanhos
        // abaixo de 12px levam tracking positivo e os títulos, negativo.
        letterSpacing: tracking,
        height: height,
      );
    }

    final baseTextTheme = TextTheme(
      // Serifada: nomes de livro, capítulo e página.
      displayLarge: serif(34, FontWeight.w600, tracking: -0.6),
      displayMedium: serif(27, FontWeight.w600, tracking: -0.45),
      headlineLarge: serif(22, FontWeight.w600, tracking: -0.3),
      headlineMedium: serif(20, FontWeight.w500, tracking: -0.2),
      titleLarge: serif(16.5, FontWeight.w600, tracking: -0.1),
      // Sans: tudo que é interface.
      headlineSmall: sans(15.5, FontWeight.w600, tracking: -0.1),
      titleMedium: sans(13.5, FontWeight.w600, tracking: -0.05),
      // Rótulo de grupo (o "CAPÍTULOS" da barra lateral): pequeno, espaçado
      // e apagado — precisa nomear a coluna sem disputar com o conteúdo.
      titleSmall: sans(11, FontWeight.w600, color: inkFaint, tracking: 0.8),
      bodyLarge: sans(14, FontWeight.w400, height: 1.55),
      bodyMedium: sans(13, FontWeight.w400, height: 1.5),
      bodySmall: sans(12, FontWeight.w400, color: inkSecondary, height: 1.45),
      labelLarge: sans(12.5, FontWeight.w600, tracking: 0.05),
      labelMedium: sans(11.5, FontWeight.w500, color: inkSecondary, tracking: 0.15),
      labelSmall: sans(11, FontWeight.w500, color: inkFaint, tracking: 0.2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaces.canvas,
      canvasColor: surfaces.canvas,
      fontFamily: kSansFontFamily,
      textTheme: baseTextTheme,
      // Sem ripple: a onda que se espalha a partir do dedo é a assinatura
      // visual do toque. No desktop o feedback é o hover, que já existe.
      splashFactory: NoSplash.splashFactory,
      // Densidade de desktop: encolhe a altura padrão de botões, tiles e
      // campos. Sem isso, cada controle carrega a área de toque de 48px
      // pensada para o dedo, e a tela inteira parece um app de celular
      // ampliado.
      visualDensity: VisualDensity.compact,
      dividerTheme: DividerThemeData(color: surfaces.hairline, thickness: 1, space: 1),
      // O mouse tem uma roda e uma barra de rolagem; a barra precisa existir
      // e ficar visível ao passar o cursor.
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.dragged)) {
            return inkSecondary.withValues(alpha: 0.45);
          }
          return inkSecondary.withValues(alpha: 0.18);
        }),
        thickness: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? 9 : 6,
        ),
        radius: const Radius.circular(radiusTight),
        crossAxisMargin: 2,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaces.panel,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge,
        iconTheme: IconThemeData(color: inkSecondary, size: 18),
      ),
      cardTheme: CardThemeData(
        color: surfaces.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSurface),
          side: BorderSide(color: surfaces.hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: inkFaint),
        labelStyle: baseTextTheme.labelMedium,
        floatingLabelStyle: baseTextTheme.labelMedium?.copyWith(color: surfaces.accentInk),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: surfaces.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: surfaces.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: surfaces.accentInk, width: 1.4),
        ),
      ),
      // O acento também é a cor do cursor e da seleção: são os dois lugares
      // onde o olho procura "onde eu estou" dentro do texto.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: surfaces.accentInk,
        selectionColor: surfaces.accentInk.withValues(alpha: 0.28),
        selectionHandleColor: surfaces.accentInk,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaces.accentFill,
          foregroundColor: Colors.white,
          disabledBackgroundColor: surfaces.accentFill.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          elevation: 0,
          textStyle: baseTextTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: surfaces.hairlineStrong),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: baseTextTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: inkSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: baseTextTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        ),
      ),
      // Um tamanho só para os ícones da interface. Ícone de 15 ao lado de um
      // de 22 é o que faz uma barra de ferramentas parecer montada com peças
      // de conjuntos diferentes.
      iconTheme: IconThemeData(color: inkSecondary, size: 17),
      chipTheme: ChipThemeData(
        backgroundColor: surfaces.panel,
        labelStyle: baseTextTheme.labelMedium,
        side: BorderSide(color: surfaces.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusTight)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaces.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSurface),
          side: BorderSide(color: surfaces.hairlineStrong),
        ),
        titleTextStyle: baseTextTheme.headlineSmall,
        contentTextStyle: baseTextTheme.bodyMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaces.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          side: BorderSide(color: surfaces.hairlineStrong),
        ),
        textStyle: baseTextTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.graphiteCard : AppColors.inkOnLight,
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.inkOnDark : AppColors.paperCanvas,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.graphiteCard : AppColors.inkOnLight,
          borderRadius: BorderRadius.circular(radiusTight),
          border: isDark ? Border.all(color: surfaces.hairlineStrong) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        waitDuration: const Duration(milliseconds: 500),
        textStyle: baseTextTheme.labelMedium?.copyWith(
          color: isDark ? AppColors.inkOnDark : AppColors.paperCanvas,
        ),
      ),
      extensions: [surfaces],
    );
  }
}
