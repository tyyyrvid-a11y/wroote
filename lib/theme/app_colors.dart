import 'package:flutter/material.dart';

/// Paleta inspirada na identidade visual da Anthropic/Claude:
/// creme/off-white quente, terracota como acento, sem tons de "SaaS" frio.
class AppColors {
  AppColors._();

  // --- Light ---
  static const Color creamBackground = Color(0xFFF5F1EA);
  static const Color creamSurface = Color(0xFFFAF8F3);
  static const Color creamSurfaceRaised = Color(0xFFFFFFFF);
  static const Color creamBorder = Color(0xFFE4DDCF);

  static const Color inkPrimary = Color(0xFF2B2924);
  static const Color inkSecondary = Color(0xFF6E6659);
  static const Color inkFaint = Color(0xFFA39C8C);

  // --- Dark ---
  static const Color duskBackground = Color(0xFF1D1B17);
  static const Color duskSurface = Color(0xFF26231D);
  static const Color duskSurfaceRaised = Color(0xFF2F2C25);
  static const Color duskBorder = Color(0xFF3B3730);

  static const Color paperPrimary = Color(0xFFEFEAE0);
  static const Color paperSecondary = Color(0xFFB7AF9E);
  static const Color paperFaint = Color(0xFF7C7669);

  // --- Acento (comum aos dois temas) ---
  static const Color terracotta = Color(0xFFCC785C);
  static const Color terracottaDeep = Color(0xFFB35F45);
  static const Color terracottaSoftLight = Color(0xFFEFD9CD);
  static const Color terracottaSoftDark = Color(0xFF4A3126);

  static const Color danger = Color(0xFFB3524A);
  static const Color success = Color(0xFF6F8F5C);

  // --- Paradas de gradiente ---
  //
  // A regra do app: o gradiente sempre vai do mais claro (topo) para o mais
  // escuro (base), imitando luz vindo de cima. A diferença entre as duas
  // paradas é pequena de propósito — o objetivo é dar volume à superfície,
  // não desenhar um degradê visível.

  /// Topo do fundo da janela, no tema claro.
  static const Color creamBackgroundTop = Color(0xFFFBF8F2);

  /// Base do fundo da janela, no tema claro.
  static const Color creamBackgroundBottom = Color(0xFFF1ECE2);

  /// Topo de um cartão claro. Levemente acima do branco puro do card.
  static const Color creamCardTop = Color(0xFFFFFFFF);

  /// Base de um cartão claro, com um toque de calor.
  static const Color creamCardBottom = Color(0xFFF7F3EB);

  /// Topo do fundo da janela, no tema escuro.
  static const Color duskBackgroundTop = Color(0xFF232019);
  static const Color duskBackgroundBottom = Color(0xFF171512);

  static const Color duskCardTop = Color(0xFF322E27);
  static const Color duskCardBottom = Color(0xFF272420);

  /// Paradas do acento, usadas em botões primários e barras de progresso.
  static const Color terracottaLight = Color(0xFFE0906F);
  static const Color terracottaBase = terracotta;

  /// Linha de luz de 1px no topo das superfícies elevadas. É o detalhe que
  /// faz o cartão parecer ter espessura em vez de ser um retângulo pintado.
  static const Color highlightLight = Color(0x99FFFFFF);
  static const Color highlightDark = Color(0x14FFFFFF);
}
