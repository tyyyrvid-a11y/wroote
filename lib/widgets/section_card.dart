import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'surfaces.dart';

/// Cartão usado para cada seção do Núcleo do Livro (sinopse, conflito
/// central, sinopses por ato, etc.).
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final List<Widget>? trailing;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      // Sem `onTap`: o cartão é um contêiner de formulário, então não pode
      // se comportar como algo clicável — nem cursor de mão, nem subida no
      // hover, que atrapalhariam quem está digitando dentro dele.
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null)
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Ícone da seção num quadrado com o acento suave ao fundo. Dá ao cabeçalho
/// um ponto de ancoragem visual e separa as seções melhor que um ícone solto.
class _SectionIcon extends StatelessWidget {
  final IconData icon;

  const _SectionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.20),
            theme.colorScheme.primary.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, size: 18, color: theme.colorScheme.primary),
    );
  }
}
