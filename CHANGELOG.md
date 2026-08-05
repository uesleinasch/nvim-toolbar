# Changelog

## [Não lançado]

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
