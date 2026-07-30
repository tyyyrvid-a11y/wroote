import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_surfaces.dart';

/// Fontes: "Source Sans 3" conduz a UI e os títulos; "Anthropic Serif"
/// é reservada para o corpo do texto dentro do editor de escrita.
const String kSansFontFamily = 'Source Sans 3';
const String kSerifFontFamily = 'Anthropic Serif';

class AppTheme {
  AppTheme._();

  static const double radiusSmall = 10;
  static const double radiusMedium = 16;
  static const double radiusLarge = 22;

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
      fontSize: 17,
      height: 1.65,
      letterSpacing: 0.1,
      color: isDark ? AppColors.paperPrimary : AppColors.inkPrimary,
    );
  }

  static ThemeData get light => _buildTheme(brightness: Brightness.light);
  static ThemeData get dark => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? AppColors.duskBackground : AppColors.creamBackground;
    final surface = isDark ? AppColors.duskSurface : AppColors.creamSurface;
    final surfaceRaised = isDark ? AppColors.duskSurfaceRaised : AppColors.creamSurfaceRaised;
    final border = isDark ? AppColors.duskBorder : AppColors.creamBorder;
    final ink = isDark ? AppColors.paperPrimary : AppColors.inkPrimary;
    final inkSecondary = isDark ? AppColors.paperSecondary : AppColors.inkSecondary;
    final softAccentBg = isDark ? AppColors.terracottaSoftDark : AppColors.terracottaSoftLight;

    // Parte de um ColorScheme.fromSeed (que preenche todos os tons
    // derivados do Material 3) e sobrescreve só o que importa para a
    // identidade visual do Wroote, evitando ter que declarar manualmente
    // cada um dos ~30 campos do ColorScheme.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.terracotta,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.terracotta,
      onPrimary: Colors.white,
      secondary: AppColors.terracottaDeep,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: surfaceRaised,
      outline: border,
    );

    final baseTextTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: kSansFontFamily, fontSize: 40, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.5),
      displayMedium: TextStyle(fontFamily: kSansFontFamily, fontSize: 32, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.4),
      headlineLarge: TextStyle(fontFamily: kSansFontFamily, fontSize: 28, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.3),
      headlineMedium: TextStyle(fontFamily: kSansFontFamily, fontSize: 24, fontWeight: FontWeight.w600, color: ink),
      headlineSmall: TextStyle(fontFamily: kSansFontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: ink),
      titleLarge: TextStyle(fontFamily: kSansFontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ink),
      titleMedium: TextStyle(fontFamily: kSansFontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      titleSmall: TextStyle(fontFamily: kSansFontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: inkSecondary),
      bodyLarge: TextStyle(fontFamily: kSansFontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: ink, height: 1.5),
      bodyMedium: TextStyle(fontFamily: kSansFontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: ink, height: 1.5),
      bodySmall: TextStyle(fontFamily: kSansFontFamily, fontSize: 12.5, fontWeight: FontWeight.w400, color: inkSecondary, height: 1.4),
      labelLarge: TextStyle(fontFamily: kSansFontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: ink),
      labelMedium: TextStyle(fontFamily: kSansFontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: inkSecondary),
      labelSmall: TextStyle(fontFamily: kSansFontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: inkSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: kSansFontFamily,
      textTheme: baseTextTheme,
      splashFactory: InkRipple.splashFactory,
      // Densidade de desktop: encolhe a altura padrão de botões, tiles e
      // campos. Sem isso, cada controle carrega a área de toque de 48px
      // pensada para o dedo, e a tela inteira parece um app de celular
      // ampliado.
      visualDensity: VisualDensity.compact,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      // O mouse tem uma roda e uma barra de rolagem; a barra precisa existir
      // e ficar visível ao passar o cursor.
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.dragged)) {
            return inkSecondary.withValues(alpha: 0.55);
          }
          return inkSecondary.withValues(alpha: 0.25);
        }),
        thickness: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? 10 : 7,
        ),
        radius: const Radius.circular(999),
        crossAxisMargin: 3,
      ),
      appBarTheme: AppBarTheme(
        // Transparente para deixar o gradiente de fundo passar por baixo.
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge,
        iconTheme: IconThemeData(color: ink),
      ),
      cardTheme: CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(fontFamily: kSansFontFamily, color: inkSecondary.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.terracotta.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          elevation: 0,
          textStyle: const TextStyle(fontFamily: kSansFontFamily, fontWeight: FontWeight.w600, fontSize: 14.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          textStyle: const TextStyle(fontFamily: kSansFontFamily, fontWeight: FontWeight.w600, fontSize: 14.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.terracottaDeep,
          textStyle: const TextStyle(fontFamily: kSansFontFamily, fontWeight: FontWeight.w600, fontSize: 14.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      iconTheme: IconThemeData(color: inkSecondary),
      chipTheme: ChipThemeData(
        backgroundColor: softAccentBg,
        labelStyle: TextStyle(fontFamily: kSansFontFamily, color: isDark ? AppColors.terracotta : AppColors.terracottaDeep, fontWeight: FontWeight.w600, fontSize: 12.5),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: border),
        ),
        titleTextStyle: baseTextTheme.headlineSmall,
        contentTextStyle: baseTextTheme.bodyMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: border),
        ),
        textStyle: baseTextTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(fontFamily: kSansFontFamily, color: background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(fontFamily: kSansFontFamily, color: background, fontSize: 12),
      ),
      extensions: [
        AppSemanticColors(
          border: border,
          softAccentBackground: softAccentBg,
          inkSecondary: inkSecondary,
          surfaceRaised: surfaceRaised,
        ),
        AppSurfaces.of(brightness),
      ],
    );
  }
}

/// Cores semânticas adicionais que não têm um slot direto no [ColorScheme]
/// do Material 3, expostas via [ThemeExtension] para uso nos widgets.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color border;
  final Color softAccentBackground;
  final Color inkSecondary;
  final Color surfaceRaised;

  const AppSemanticColors({
    required this.border,
    required this.softAccentBackground,
    required this.inkSecondary,
    required this.surfaceRaised,
  });

  @override
  AppSemanticColors copyWith({Color? border, Color? softAccentBackground, Color? inkSecondary, Color? surfaceRaised}) {
    return AppSemanticColors(
      border: border ?? this.border,
      softAccentBackground: softAccentBackground ?? this.softAccentBackground,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      border: Color.lerp(border, other.border, t)!,
      softAccentBackground: Color.lerp(softAccentBackground, other.softAccentBackground, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors => Theme.of(this).extension<AppSemanticColors>()!;
}
