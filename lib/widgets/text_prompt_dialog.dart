import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import 'surfaces.dart';

/// Diálogo genérico com um único campo de texto — usado para criar e
/// renomear livros, capítulos e páginas.
class TextPromptDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final String confirmLabel;

  const TextPromptDialog({
    super.key,
    required this.title,
    required this.label,
    this.initialValue = '',
    this.confirmLabel = 'Salvar',
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String label,
    String initialValue = '',
    String confirmLabel = 'Salvar',
  }) async {
    context.sounds.play(UiSound.open);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: title,
        label: label,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
      ),
    );
    // Sem valor = o usuário desistiu. Confirmar deixa o som para quem
    // chamou, que sabe se criou, renomeou ou nada aconteceu.
    if (context.mounted && result == null) context.sounds.play(UiSound.close);
    return result;
  }

  @override
  State<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<TextPromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    Navigator.of(context).pop(value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 340,
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(labelText: widget.label),
          onSubmitted: (_) => _submit(),
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        SecondaryButton(
          label: 'Cancelar',
          sound: null, // O `close` toca ao fechar o diálogo.
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        PrimaryButton(
          label: widget.confirmLabel,
          onPressed: _submit,
          // Quem chamou o diálogo toca o som do resultado.
          sound: null,
        ),
      ],
    );
  }
}
