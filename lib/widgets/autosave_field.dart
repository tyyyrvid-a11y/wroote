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

  const AutosaveField({
    super.key,
    this.label,
    this.hint,
    required this.initialValue,
    required this.onChanged,
    this.minLines,
    this.maxLines = 1,
    this.style,
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
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        alignLabelWithHint: true,
      ),
    );
  }
}
