import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Separa milhares com ponto: 12480 → 12.480.
///
/// Um número de cinco dígitos sem separador força quem lê a contar casas.
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Texto em mono para números e atalhos de teclado.
///
/// A mono é o terceiro papel tipográfico do app e serve a uma coisa só:
/// valores que mudam. Ver o desenho mono já diz "isto é uma medida", antes
/// mesmo de ler o número.
class MonoText extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;

  const MonoText(
    this.text, {
    super.key,
    this.size = 11.5,
    this.color,
    this.weight = FontWeight.w400,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.mono(context, size: size, color: color, weight: weight),
    );
  }
}

/// Contagem de palavras da página aberta, no canto do cabeçalho do editor.
///
/// Sem cápsula, sem cor de acento: é um instrumento de medida, não um aviso.
class WordCountReadout extends StatelessWidget {
  final int count;

  const WordCountReadout({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = AppTheme.mono(
      context,
      size: 11.5,
      color: theme.textTheme.labelSmall?.color,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // O número troca a cada tecla digitada; sem a transição ele "pisca"
        // no canto da tela e rouba a atenção de quem escreve.
        AnimatedSwitcher(
          duration: AppMotion.fast,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(formatCount(count), key: ValueKey(count), style: style),
        ),
        const SizedBox(width: 5),
        Text(count == 1 ? 'palavra' : 'palavras', style: style),
      ],
    );
  }
}

/// Barra de progresso: uma linha fina, chapada, no acento. Sem gradiente,
/// sem cantos redondos, sem trilho fundo — só a proporção.
class ProgressLine extends StatelessWidget {
  final double value;
  final double height;

  const ProgressLine({super.key, required this.value, this.height = 3});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                heightFactor: 1,
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
