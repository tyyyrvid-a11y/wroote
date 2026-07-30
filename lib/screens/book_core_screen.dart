import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/book_core_provider.dart';
import '../widgets/autosave_field.dart';
import '../widgets/character_editor_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/section_card.dart';

/// Tela de planejamento: sinopse geral, personagens, estimativa de
/// páginas, conflito central e as sinopses de introdução, desenvolvimento,
/// clímax e fim. Tudo com autosave — não existe botão "Salvar".
class BookCoreScreen extends StatelessWidget {
  const BookCoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookCoreProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final core = provider.core;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      children: [
        Row(
          children: [
            Icon(Icons.cloud_done_outlined, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('Salvo automaticamente enquanto você escreve', style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Sinopse geral',
          subtitle: 'Do que trata este livro, em poucos parágrafos',
          icon: Icons.auto_stories_outlined,
          child: AutosaveField(
            initialValue: core.synopsis,
            onChanged: provider.updateSynopsis,
            hint: 'Escreva aqui a sinopse geral do livro…',
            minLines: 4,
            maxLines: 12,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Conflito central',
          subtitle: 'O que move a história para frente',
          icon: Icons.bolt_outlined,
          child: AutosaveField(
            initialValue: core.centralConflict,
            onChanged: provider.updateCentralConflict,
            hint: 'Qual é o conflito principal do livro?',
            minLines: 3,
            maxLines: 8,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Estimativa de páginas',
          subtitle: 'Meta aproximada de tamanho do livro',
          icon: Icons.straighten_outlined,
          child: _PageEstimateStepper(
            value: core.pageEstimate,
            onChanged: provider.updatePageEstimate,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Personagens',
          subtitle: 'Nome, descrição e detalhes livres',
          icon: Icons.people_outline,
          trailing: [
            IconButton(
              tooltip: 'Adicionar personagem',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => provider.addCharacter(),
            ),
          ],
          child: provider.characters.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Nenhum personagem ainda.', style: theme.textTheme.bodySmall),
                )
              : Column(
                  children: [
                    for (final character in provider.characters)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CharacterEditorCard(
                          key: ValueKey(character.id),
                          character: character,
                          onChanged: provider.updateCharacter,
                          onDelete: () async {
                            final confirmed = await ConfirmDialog.show(
                              context,
                              title: 'Excluir "${character.name}"?',
                              message: 'Este personagem será removido do livro.',
                            );
                            if (confirmed) {
                              await provider.deleteCharacter(character.id);
                            }
                          },
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Introdução',
          subtitle: 'Sinopse do início da história',
          icon: Icons.looks_one_outlined,
          child: AutosaveField(
            initialValue: core.introSynopsis,
            onChanged: provider.updateIntroSynopsis,
            minLines: 3,
            maxLines: 8,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Desenvolvimento',
          subtitle: 'Sinopse do meio da história',
          icon: Icons.looks_two_outlined,
          child: AutosaveField(
            initialValue: core.developmentSynopsis,
            onChanged: provider.updateDevelopmentSynopsis,
            minLines: 3,
            maxLines: 8,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Clímax',
          subtitle: 'Sinopse do ponto de virada decisivo',
          icon: Icons.looks_3_outlined,
          child: AutosaveField(
            initialValue: core.climaxSynopsis,
            onChanged: provider.updateClimaxSynopsis,
            minLines: 3,
            maxLines: 8,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Fim',
          subtitle: 'Sinopse da conclusão da história',
          icon: Icons.looks_4_outlined,
          child: AutosaveField(
            initialValue: core.endingSynopsis,
            onChanged: provider.updateEndingSynopsis,
            minLines: 3,
            maxLines: 8,
          ),
        ),
      ],
    );
  }
}

class _PageEstimateStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _PageEstimateStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _stepButton(context, '−10', () => onChanged(value - 10)),
        _stepButton(context, '−1', () => onChanged(value - 1)),
        Expanded(
          child: Center(
            child: Text(
              '$value ${value == 1 ? 'página' : 'páginas'}',
              style: theme.textTheme.headlineSmall,
            ),
          ),
        ),
        _stepButton(context, '+1', () => onChanged(value + 1)),
        _stepButton(context, '+10', () => onChanged(value + 10)),
      ],
    );
  }

  Widget _stepButton(BuildContext context, String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        minimumSize: const Size(48, 44),
      ),
      child: Text(label),
    );
  }
}
