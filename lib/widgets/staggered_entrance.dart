import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Faz o filho entrar com fade + um deslocamento mínimo para cima, atrasado
/// conforme [index].
///
/// A entrada encenada existe para dar ao olho uma ordem de leitura, não para
/// ser notada: são 190ms e 6px, e o atraso entre itens tem teto em
/// [AppMotion.staggerCap]. Se der para acompanhar os cartões chegando um a
/// um, está lento demais.
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;

  /// Distância vertical percorrida na entrada.
  final double offset;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.offset = 6,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.base,
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
