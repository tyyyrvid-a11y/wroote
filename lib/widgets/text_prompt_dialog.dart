import 'package:flutter/material.dart';

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
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: title,
        label: label,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
      ),
    );
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
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
