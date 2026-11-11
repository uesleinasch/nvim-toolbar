# Changelog

## [0.1.1] — 2026-11-11

### Corrigido

- Abrir arquivo pelo neo-tree logo após iniciar não dá mais `E1513` (`winfixbuf`)
  na janela da barra: sem histórico de janelas, o neo-tree escolhia a barra. A
  barra agora entra sozinha em `open_files_do_not_replace_types` do neo-tree,
  sem precisar configurar nada.

### Interno

- Automação GitFlow: validação de branch e título de PR, CodeQL dos workflows,
  Dependabot de actions e GitHub Release automática a partir de tag anotada.

## [0.1.0] — 2026-08-05

Primeira versão pública: barra clicável com 6 grupos por intenção e 5 ações
diretas, menu de alvos para operadores, eco pedagógico do atalho executado,
renderers de `tabline` e de janela dedicada, hover, `:checkhealth`, vimdoc e
suíte de testes com cliques de mouse reais.

### Adicionado

- Opção `groups` no `setup()` substitui o catálogo padrão de verdade.
- A barra em janela migra para a tabpage atual em vez de ficar órfã.
- Redesenho automático em `VimResized` (o modo compacto recalcula).
- `position` inválida gera aviso no `setup()` e erro no `:checkhealth`.
- Guard de versão mínima (Neovim 0.10) com mensagem clara.
- Vimdoc (`:help nvim-toolbar`), LICENSE (MIT), CI e CHANGELOG.

### Corrigido

- Clique em item de teclas durante Insert/Replace/Select/Terminal não digita
  mais as teclas como texto: a barra volta ao Normal antes de executar.
- Menu aberto a partir do Insert entra em modo Normal (os atalhos do menu
  funcionam).
- Erro de comando Ex (`:w` sem nome, `:bd` sem salvar) vira mensagem limpa em
  vez de stack trace, e o menu fecha mesmo assim.
- `:ToolbarDisable` restaura os mapeamentos de mouse e o `<MouseMove>` /
  `mousemoveevent` que o usuário já tinha.
- `setup()` chamado de novo reconfigura de verdade (troca de renderer,
  hover etc.).
- Com a barra em janela, `:q` na última janela de código encerra a sessão de
  uma vez.
- Itens de comando (`:w`, `:bn`, ...) não estouram mais erro de `keys` nulo.
- Trocar de grupo com o menu aberto no renderer de janela leva um clique, não
  dois.
- Clique nas abas da tabline (heirline, tabpages) não é mais tratado como
  clique na toolbar (filtro de `winrow` no hit-test da barra em janela).
- Abrir arquivo pelo neo-tree (ou qualquer plugin que procure "uma janela
  qualquer") não sequestra mais a janela da barra: ela agora usa `winfixbuf`.
- A criação da barra durante o startup é adiada para depois do `VimEnter`,
  evitando o split fantasma que o Neovim abre quando a primeira janela tem
  `winfixbuf`.
- Sidebars (neo-tree e afins, `buftype=nofile`) não contam mais como janela de
  código: `:q` na última janela de arquivo com a tree aberta fecha a barra em
  vez de deixá-la herdar o espaço inteiro, e o guard de foco não devolve mais
  o cursor para a sidebar. A barra volta sozinha quando um arquivo reaparece.
