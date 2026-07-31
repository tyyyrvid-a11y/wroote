import 'package:flutter/material.dart';

/// Campo de texto que mantém seu próprio [TextEditingController] (para o
/// cursor não pular durante o autosave) e reporta cada alteração para o
/// provider, que decide quando persistir (debounce).
class AutosaveField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int? minLines;
  final int? maxLines;
  final TextStyle? style;

  /// Sem moldura nem fundo: o campo se parece com o texto que contém, e a
  /// edição acontece no lugar. Usado no título da página, que é um nome
  /// exibido — não um campo de formulário.
  final bool bare;

  const AutosaveField({
    super.key,
    this.label,
    this.hint,
    required this.initialValue,
    required this.onChanged,
    this.minLines,
    this.maxLines = 1,
    this.style,
    this.bare = false,
  });

  @override
  State<AutosaveField> createState() => _AutosaveFieldState();
}

class _AutosaveFieldState extends State<AutosaveField> {
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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: widget.style,
      decoration: widget.bare
          ? InputDecoration(
              hintText: widget.hint,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintStyle: widget.style?.copyWith(
                color: Theme.of(context).textTheme.labelSmall?.color,
              ),
            )
          : InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              alignLabelWithHint: true,
            ),
    );
  }
}
