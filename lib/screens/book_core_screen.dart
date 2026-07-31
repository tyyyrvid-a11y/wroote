import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/book_core_provider.dart';
import '../services/sound_service.dart';
import '../widgets/autosave_field.dart';
import '../widgets/character_editor_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/counters.dart';
import '../widgets/section_card.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/surfaces.dart';

/// Tela de planejamento: sinopse geral, personagens, estimativa de
/// páginas, conflito central e as sinopses de introdução, desenvolvimento,
/// clímax e fim. Tudo com autosave — não existe botão "Salvar".
class BookCoreScreen extends StatelessWidget {
  const BookCoreScreen({super.key});

  /// Abaixo desta largura o conteúdo volta para uma coluna só. O valor é a
  /// soma de duas colunas confortáveis (~420px cada) mais o respiro entre e
  /// ao redor delas.
  static const double _twoColumnBreakpoint = 1000;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookCoreProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= _twoColumnBreakpoint;
        final narrative = _narrativeSections(context, provider);
        final structure = _structureSections(context, provider);

        return ContentColumn(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ScreenHeading(
                  title: 'Núcleo do livro',
                  subtitle: 'O planejamento que sustenta a escrita',
                ),
                const SizedBox(height: 20),
                if (twoColumns)
                  // Duas colunas independentes, cada uma com o seu próprio
                  // empilhamento. Alinhadas pelo topo para que a coluna mais
                  // curta não estique os cartões junto com a mais longa.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _SectionStack(sections: narrative)),
                      const SizedBox(width: 16),
                      Expanded(child: _SectionStack(sections: structure)),
                    ],
                  )
                else
                  _SectionStack(sections: [...narrative, ...structure]),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _narrativeSections(BuildContext context, BookCoreProvider provider) {
    final core = provider.core;
    final theme = Theme.of(context);

    return [
      SectionCard(
        title: 'Sinopse geral',
        subtitle: 'Do que trata este livro, em poucos parágrafos',
        icon: Icons.auto_stories_outlined,
        child: AutosaveField(
          initialValue: core.synopsis,
          onChanged: provider.updateSynopsis,
          hint: 'Escreva aqui a sinopse geral do livro…',
          minLines: 5,
          maxLines: 14,
        ),
      ),
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
      SectionCard(
        title: 'Personagens',
        subtitle: 'Nome, descrição e detalhes livres',
        icon: Icons.people_outline,
        trailing: [
          AppIconButton(
            icon: Icons.add,
            tooltip: 'Adicionar personagem',
            size: 16,
            sound: UiSound.success,
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
                          if (!confirmed || !context.mounted) return;
                          await provider.deleteCharacter(character.id);
                          if (context.mounted) context.sounds.play(UiSound.delete);
                        },
                      ),
                    ),
                ],
              ),
      ),
    ];
  }

  List<Widget> _structureSections(BuildContext context, BookCoreProvider provider) {
    final core = provider.core;

    return [
      SectionCard(
        title: 'Estimativa de páginas',
        subtitle: 'Meta aproximada de tamanho do livro',
        icon: Icons.straighten_outlined,
        child: _PageEstimateStepper(
          value: core.pageEstimate,
          onChanged: provider.updatePageEstimate,
        ),
      ),
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
    ];
  }
}

/// Empilha seções com espaçamento e entrada encenada uniformes.
class _SectionStack extends StatelessWidget {
  final List<Widget> sections;

  const _SectionStack({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == sections.length - 1 ? 0 : 16),
            child: StaggeredEntrance(index: i, child: sections[i]),
          ),
      ],
    );
  }
}

/// Cabeçalho de tela dentro do painel de conteúdo.
class _ScreenHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ScreenHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineLarge),
        const SizedBox(height: 2),
        Text(subtitle, style: theme.textTheme.bodySmall),
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
        _stepButton(context, Icons.keyboard_double_arrow_left, 'Menos 10', () => onChanged(value - 10)),
        _stepButton(context, Icons.remove, 'Menos 1', () => onChanged(value - 1)),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mono: é uma medida, e o dígito tabular impede que o número
                // dance de largura enquanto se aperta o botão.
                MonoText(
                  formatCount(value),
                  size: 26,
                  weight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(height: 4),
                Text(
                  value == 1 ? 'página' : 'páginas',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
        _stepButton(context, Icons.add, 'Mais 1', () => onChanged(value + 1)),
        _stepButton(context, Icons.keyboard_double_arrow_right, 'Mais 10', () => onChanged(value + 10)),
      ],
    );
  }

  Widget _stepButton(BuildContext context, IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AppIconButton(
        icon: icon,
        tooltip: tooltip,
        size: 16,
        sound: UiSound.toggle,
        onPressed: onTap,
      ),
    );
  }
}
