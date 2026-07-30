import 'package:flutter/material.dart';

/// Tokens de animação do app. Centralizar durações e curvas é o que faz
/// as animações parecerem parte de um sistema só, em vez de um monte de
/// `Duration(milliseconds: 300)` espalhado pelo código.
///
/// A escala segue a lógica de UI de desktop: o cursor do mouse é preciso e
/// rápido, então feedback direto (hover, press) precisa ser quase
/// instantâneo — animação lenta em hover dá sensação de travamento.
class AppMotion {
  AppMotion._();

  /// Hover, press, mudança de cor — reage "junto" com o cursor.
  static const Duration instant = Duration(milliseconds: 90);

  /// Padrão para a maioria das transições de estado.
  static const Duration fast = Duration(milliseconds: 160);

  /// Expandir/recolher, troca de conteúdo.
  static const Duration base = Duration(milliseconds: 240);

  /// Transições de tela e entradas encenadas.
  static const Duration slow = Duration(milliseconds: 380);

  /// Desaceleração suave — o padrão para algo que entra ou se move.
  static const Curve enter = Curves.easeOutCubic;

  /// Desaceleração acentuada, com um "assentar" mais longo no fim.
  static const Curve emphasized = Curves.easeOutQuint;

  /// Para algo que sai de cena.
  static const Curve exit = Curves.easeInCubic;

  /// Movimento com um leve exagero no fim, para elementos que "aparecem".
  static const Curve spring = Curves.easeOutBack;

  /// Atraso entre itens consecutivos numa entrada encenada (grid, lista).
  static const Duration stagger = Duration(milliseconds: 45);

  /// Teto do atraso encenado: sem isso, o 40º card da biblioteca demoraria
  /// quase dois segundos para aparecer.
  static const Duration staggerCap = Duration(milliseconds: 400);

  /// Calcula o atraso de entrada do item [index] respeitando o teto.
  static Duration staggerDelay(int index) {
    final ms = stagger.inMilliseconds * index;
    return Duration(milliseconds: ms.clamp(0, staggerCap.inMilliseconds));
  }
}
