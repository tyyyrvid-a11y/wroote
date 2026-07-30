import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class WordCountBadge extends StatelessWidget {
  final int count;

  const WordCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.short_text, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 7),
          // O número troca a cada tecla digitada; sem a transição ele
          // "pisca" no canto da tela e rouba a atenção de quem escreve.
          AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Text(
              '$count',
              key: ValueKey(count),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count == 1 ? 'palavra' : 'palavras',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
