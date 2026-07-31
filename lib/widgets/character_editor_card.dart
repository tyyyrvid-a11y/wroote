import 'package:flutter/material.dart';

import '../models/character.dart';
import '../services/sound_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import 'autosave_field.dart';
import 'surfaces.dart';

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
    final surfaces = context.surfaces;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Cartão aninhado dentro do cartão de seção: recua para a cor de
        // painel para se ler como um nível abaixo, em vez de competir com o
        // cartão que o contém.
        color: surfaces.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: surfaces.hairline),
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
              AppIconButton(
                icon: Icons.delete_outline,
                tooltip: 'Excluir personagem',
                size: 16,
                color: theme.colorScheme.error,
                sound: UiSound.tap,
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
