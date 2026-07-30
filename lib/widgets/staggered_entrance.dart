import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Faz o filho entrar com fade + deslocamento para cima, atrasado conforme
/// [index].
///
/// A entrada encenada existe para dar ao olho uma ordem de leitura: os
/// cartões aparecem na sequência em que devem ser lidos, em vez de a grade
/// inteira piscar de uma vez. O atraso tem teto em [AppMotion.staggerCap]
/// para que bibliotecas grandes não fiquem lentas.
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;

  /// Distância vertical percorrida na entrada.
  final double offset;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.offset = 12,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  // Criado uma vez, e não dentro do `build`: um CurvedAnimation por
  // reconstrução acumula listeners no controller.
  late final Animation<double> _curved =
      CurvedAnimation(parent: _controller, curve: AppMotion.enter);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(AppMotion.staggerDelay(widget.index));
    // A tela pode ter sido fechada durante o atraso.
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        return Opacity(
          // `clamp` porque uma curva com exagero no fim pode passar de 1,
          // e Opacity lança fora do intervalo 0..1.
          opacity: _curved.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _curved.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
