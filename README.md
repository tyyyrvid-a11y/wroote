# Wroote

Um espaço tranquilo para planejar e escrever livros. App Flutter para desktop
(Windows, macOS e Linux), sem backend — tudo fica salvo localmente em um
banco SQLite.

## Telas

- **Biblioteca** — menu inicial com os seus livros (título e progresso
  estimado), criação/renomeação/exclusão e busca por título.
- **Núcleo do livro** — planejamento: sinopse geral, personagens (nome,
  descrição, detalhes livres), estimativa de páginas, conflito central e
  as sinopses de introdução, desenvolvimento, clímax e fim. Autosave.
- **Escrita de páginas** — editor de texto rico (negrito, itálico),
  contador de palavras em tempo real, navegação entre capítulos/páginas
  pela barra lateral. Autosave.

## Stack técnica

- Flutter (stable), desktop habilitado para Windows/macOS/Linux
- Estado: [`provider`](https://pub.dev/packages/provider)
- Persistência: SQLite via `sqflite` + `sqflite_common_ffi` (arquivo local
  em `getApplicationSupportDirectory()`, sem servidor/backend)
- Editor rico: [`flutter_quill`](https://pub.dev/packages/flutter_quill)
- Camadas: `lib/models`, `lib/screens`, `lib/widgets`, `lib/services`,
  `lib/theme`

## Identidade visual

Software de escrita para desktop, na linha de um Scrivener ou Ulysses:
neutro, denso e sem decoração. As regras estão em `lib/theme/`:

- **Paleta** (`app_colors.dart`) — grafite `#1C1B1A` no escuro, papel
  off-white frio `#EDECE8` no claro. Um acento só, azul petróleo `#2B5C63`,
  reservado para a ação primária, o estado ativo e o cursor. Texto em cinza
  quente, nunca preto ou branco puros.
- **Superfícies** (`app_surfaces.dart`) — cor chapada, linha de 1px e
  espaçamento. Sem gradiente; sombra só em diálogos e menus.
- **Tipografia** (`app_theme.dart`) — três papéis sem sobreposição:
  serifada para nomes de livro/capítulo/página e para o corpo do editor,
  sans para toda a interface, mono para contadores e atalhos. Hierarquia:
  livro > capítulo > página > corpo.
- **Raios** — de 3 a 6px, em toda parte.
- **Movimento** (`app_motion.dart`) — 110 a 190ms, sem overshoot.

Fontes empacotadas: **Source Sans 3** (UI) e **Anthropic Serif** (títulos e
corpo do editor). A mono vem do sistema, em cascata (`Consolas`, `SF Mono`,
`DejaVu Sans Mono`…).

Suporte a dark mode (alternável pelo botão no topo da Biblioteca).

> ⚠️ **Sobre as fontes**: os arquivos em `fonts/` são fontes proprietárias
> da Anthropic, incluídas aqui apenas para uso pessoal/local. Antes de
> tornar este repositório **público** ou fazer push, confirme que você
> tem permissão para redistribuí-las; se não tiver, remova `fonts/*.otf`
> e `fonts/*.ttf` do controle de versão (adicione ao `.gitignore`) e
> troque as declarações em `pubspec.yaml` por uma fonte de fallback.

## Rodando localmente

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable) instalado e no PATH.

```bash
# 1. Gera os runners nativos de desktop (não versionados neste repo,
#    veja o motivo no .gitignore). Faça isso uma vez após clonar:
flutter create --platforms=windows,macos,linux .

# 2. Instala as dependências
flutter pub get

# 3. Roda no seu SO
flutter run -d windows   # ou macos / linux
```

Para gerar um build de release localmente:

```bash
flutter build windows --release   # ou macos / linux
```

## CI/CD

`.github/workflows/build.yml` builda o app em matriz
(`windows-latest` / `macos-latest` / `ubuntu-latest`) a cada push/PR na
`main` e também sob demanda (`workflow_dispatch`). No Linux instala
`ninja-build`, `libgtk-3-dev`, `clang` e `cmake` antes do build. Os
artefatos de cada plataforma ficam disponíveis na aba **Actions** do
GitHub.

## Onde os dados ficam salvos

Um único arquivo `wroote.db` (SQLite) na pasta de dados do app do
sistema operacional (via `path_provider`). Nenhuma informação sai da
sua máquina.
