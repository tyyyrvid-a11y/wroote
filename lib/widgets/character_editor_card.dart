import 'package:flutter/material.dart';

import '../models/character.dart';
import '../theme/app_theme.dart';
import 'autosave_field.dart';

class CharacterEditorCard extends StatelessWidget {
  final BookCharacter character;
  final ValueChanged<BookCharacter> onChanged;
  final VoidCallback onDelete;

  const CharacterEditorCard({
    super.key,
    required this.character,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.semanticColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: context.semanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AutosaveField(
                  label: 'Nome',
                  initialValue: character.name,
                  onChanged: (v) => onChanged(character.copyWith(name: v)),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Excluir personagem',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AutosaveField(
            label: 'Descrição',
            hint: 'Quem é essa pessoa em uma frase',
            initialValue: character.description,
            onChanged: (v) => onChanged(character.copyWith(description: v)),
          ),
          const SizedBox(height: 10),
          AutosaveField(
            label: 'Detalhes',
            hint: 'Aparência, personalidade, história, motivações…',
            initialValue: character.details,
            onChanged: (v) => onChanged(character.copyWith(details: v)),
            minLines: 3,
            maxLines: 8,
          ),
        ],
      ),
    );
  }
}
