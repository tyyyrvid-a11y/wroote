import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import 'surfaces.dart';

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
        return AlertDialog(
          // Sem ícone de alerta: quem abre um diálogo de exclusão já sabe
          // que é sério. O aviso está no texto e na cor do botão.
          title: Text(title),
          // Largura fixa, e não a largura natural da mensagem: sem isso um
          // "Excluir 'A'?" de mensagem curta gera um diálogo estreito
          // demais, e cada diálogo do app tem um tamanho diferente.
          content: SizedBox(width: 340, child: Text(message)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            // Um Row só, não dois itens soltos na lista `actions`: o
            // Flutter embrulha essa lista num OverflowBar que decide, por
            // conta própria, se os botões cabem lado a lado — e com um
            // título curto essa conta erra e empilha os dois, esticando o
            // primeiro para a largura inteira do diálogo. Um único filho
            // não deixa essa decisão acontecer.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: 'Cancelar',
                  sound: null, // O `close` toca ao fechar o diálogo.
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                const SizedBox(width: 10),
                PrimaryButton(
                  label: confirmLabel,
                  destructive: true,
                  // Quem chamou o diálogo toca o som da ação concluída.
                  sound: null,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
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
