import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'hoverable.dart';

/// Diálogo genérico de confirmação para ações destrutivas (excluir livro,
/// capítulo, página ou personagem).
class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Excluir',
  }) async {
    context.sounds.play(UiSound.open);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 28),
          title: Text(title),
          content: Text(message),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 4),
            _DangerButton(
              label: confirmLabel,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    // Cancelar fecha em silêncio pelo som de `close`; confirmar deixa o som
    // para quem chamou, que sabe qual ação de fato aconteceu.
    if (context.mounted && result != true) context.sounds.play(UiSound.close);
    return result ?? false;
  }
}

/// Botão de confirmação destrutiva. Mesmo desenho do [AccentButton], mas
/// com o gradiente de perigo — a cor é o aviso.
class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DangerButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      onTap: onPressed,
      tapSound: null, // Quem chamou o diálogo toca o som da ação concluída.
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: AppMotion.instant,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFC96A61), AppColors.danger],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: PressScale(
            pressed: pressed,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: kSansFontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
