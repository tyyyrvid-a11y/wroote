import 'package:flutter/material.dart';

/// Paleta do Wroote.
///
/// Duas regras sustentam tudo aqui:
///
/// 1. **Nada de calor no cinza.** O tema escuro é grafite (neutro puxando
///    para o frio) e o claro é papel off-white frio. Bege e creme dão ao app
///    ar de "caderno de anotações"; um software de escrita profissional
///    precisa desaparecer atrás do texto.
/// 2. **Um acento só, usado com parcimônia.** O azul petróleo aparece na
///    ação primária, no estado ativo e no cursor — em nenhum outro lugar.
///    Acento espalhado é o que faz uma interface parecer um SaaS.
///
/// Texto nunca é preto puro nem branco puro: os dois "vibram" contra o fundo
/// e cansam em sessões longas de leitura.
class AppColors {
  AppColors._();

  // --- Escuro: grafite ---

  /// Fundo da janela.
  static const Color graphiteCanvas = Color(0xFF1C1B1A);

  /// Barras laterais e faixas de ferramentas — um degrau abaixo do canvas,
  /// para o conteúdo ficar em primeiro plano sem precisar de sombra.
  static const Color graphitePanel = Color(0xFF171615);

  /// Superfícies de conteúdo (cartões, folha do editor).
  static const Color graphiteCard = Color(0xFF232221);
  static const Color graphiteCardHover = Color(0xFF2A2827);

  /// Divisores de 1px. O "forte" é para a borda de um elemento sob o cursor.
  static const Color graphiteHairline = Color(0xFF302E2C);
  static const Color graphiteHairlineStrong = Color(0xFF454240);

  static const Color inkOnDark = Color(0xFFE6E3DE);
  static const Color inkOnDarkSecondary = Color(0xFF9E9A93);
  static const Color inkOnDarkFaint = Color(0xFF6B6762);

  // --- Claro: papel off-white frio ---

  static const Color paperCanvas = Color(0xFFEDECE8);
  static const Color paperPanel = Color(0xFFE6E5E0);
  static const Color paperCard = Color(0xFFF6F5F2);
  static const Color paperCardHover = Color(0xFFFCFBF9);

  static const Color paperHairline = Color(0xFFD7D5CF);
  static const Color paperHairlineStrong = Color(0xFFBEBBB4);

  static const Color inkOnLight = Color(0xFF2A2926);
  static const Color inkOnLightSecondary = Color(0xFF615D57);
  static const Color inkOnLightFaint = Color(0xFF8C8880);

  // --- Acento: azul petróleo ---
  //
  // Para trocar a identidade por verde-oliva escuro, basta mudar estas três
  // constantes para 0xFF3D4A3A / 0xFF47563F / 0xFF8DA07F. Nenhum widget
  // conhece o valor da cor: todos leem `AppSurfaces.accentFill/accentInk`.

  /// Preenchimento da ação primária. Branco sobre esta cor dá 7:1.
  static const Color accent = Color(0xFF2B5C63);

  /// Mesmo acento um pouco mais claro, para o hover do preenchimento e para
  /// o botão no tema escuro (onde o tom cheio afundaria no grafite).
  static const Color accentRaised = Color(0xFF35707A);

  /// Versão legível como *texto* sobre grafite. O acento cheio tem contraste
  /// de 2,3:1 contra o fundo escuro — ilegível para rótulos e marcadores.
  static const Color accentOnDark = Color(0xFF6BA3AB);

  // --- Semânticas ---

  static const Color dangerLight = Color(0xFF9E463F);
  static const Color dangerDark = Color(0xFFC97D74);
}
