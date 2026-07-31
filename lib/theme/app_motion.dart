import 'package:flutter/material.dart';

/// Tokens de animação do app. Centralizar durações e curvas é o que faz
/// as animações parecerem parte de um sistema só, em vez de um monte de
/// `Duration(milliseconds: 300)` espalhado pelo código.
///
/// A escala inteira cabe entre 100 e 200ms, e nenhuma curva ultrapassa o
/// valor final. Movimento com overshoot ("bounce") comunica brincadeira; um
/// editor de texto precisa comunicar que a máquina respondeu na hora. Acima
/// de ~200ms a transição deixa de ser feedback e vira espera.
class AppMotion {
  AppMotion._();

  /// Hover, press, mudança de cor — reage "junto" com o cursor.
  static const Duration instant = Duration(milliseconds: 110);

  /// Padrão para a maioria das transições de estado.
  static const Duration fast = Duration(milliseconds: 150);

  /// Expandir/recolher, troca de conteúdo, entradas.
  static const Duration base = Duration(milliseconds: 190);

  /// Desaceleração simples: sai rápido, assenta sem passar do ponto.
  static const Curve enter = Curves.easeOutCubic;

  /// Para algo que sai de cena.
  static const Curve exit = Curves.easeInCubic;

  /// Atraso entre itens consecutivos numa entrada encenada (grade, lista).
  /// Curto de propósito: o suficiente para a lista não piscar inteira de uma
  /// vez, curto demais para alguém conseguir "assistir" à animação.
  static const Duration stagger = Duration(milliseconds: 16);

  /// Teto do atraso encenado: sem isso, o 40º card da biblioteca esperaria
  /// meio segundo para aparecer.
  static const Duration staggerCap = Duration(milliseconds: 100);

  /// Calcula o atraso de entrada do item [index] respeitando o teto.
  static Duration staggerDelay(int index) {
    final ms = stagger.inMilliseconds * index;
    return Duration(milliseconds: ms.clamp(0, staggerCap.inMilliseconds));
  }
}
