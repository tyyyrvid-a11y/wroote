import 'package:flutter/material.dart';

import 'surfaces.dart';

/// Cartão usado para cada seção do Núcleo do Livro (sinopse, conflito
/// central, sinopses por ato, etc.).
///
/// O ícone é monocromático e do mesmo tamanho dos demais ícones do app —
/// sem o quadrado tingido de acento que fazia cada seção parecer um recurso
/// anunciado numa página de vendas.
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
      // se comportar como algo clicável — nem cursor de mão, nem reação ao
      // hover, que atrapalhariam quem está digitando dentro dele.
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 16, color: theme.textTheme.labelSmall?.color),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
