# nvim-toolbar

[![CI](https://github.com/uesleinasch/nvim-toolbar/actions/workflows/ci.yml/badge.svg)](https://github.com/uesleinasch/nvim-toolbar/actions/workflows/ci.yml)
[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![Licença: MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-blue.svg)](LICENSE)

Uma barra de ferramentas clicável para o Neovim, agrupada por intenção como no Word ou
no VSCode — e que **ensina o atalho enquanto é usada**.

```
 Arquivo ▾ Navegar ▾ Selecionar ▾ Editar ▾ Texto ▾ Buscar ▾ │ ↶ u  ↷ ^r  :w  ESC  ✕ :qa
```

Todo rótulo começa pelo atalho real (`y - Copia`, `d / x - Recorta`, `^r - Refaz`), e
depois de cada ação a barra ecoa a tecla que a produziu (`yy → Copia a linha inteira`).
A ideia é ser uma rampa: você clica hoje e digita amanhã.

## Por que os operadores abrem um submenu

No Vim, `y`, `d`, `c`, `gu` não fazem nada sozinhos — precisam de um alvo. A toolbar
resolve isso pelo contexto:

- **Com texto selecionado**, o clique age na seleção, na hora.
- **Sem seleção**, o clique pergunta o alvo: a linha inteira, a palavra, até o fim da
  linha, dentro de `{}`, dentro de `()`, dentro de `""`, o parágrafo, o arquivo todo.
  Cada opção mostra o atalho composto (`yiw`, `y$`, `yi{`).

É a gramática operador + alvo do Vim, visível e clicável em vez de decorada.

## O que vem dentro

- **6 grupos por intenção** — Arquivo, Navegar, Selecionar, Editar, Texto, Buscar —
  e 5 ações diretas (desfazer, refazer, salvar, ESC, sair), tudo com o atalho real
  no rótulo.
- **Eco pedagógico**: cada ação executada mostra a tecla que a produziu.
- **Duas moradas**: na `tabline` (1 linha) ou em janela dedicada (preserva as abas
  de buffer do heirline/bufferline).
- **Consciente de contexto**: age na seleção visual quando ela existe, sai do modo
  Insert antes de comandos de modo Normal, respeita `winfixbuf`, não rouba cliques
  da tabline nem some quando você troca de tabpage.
- **Catálogo substituível** (`groups`), destaques ligados ao seu tema, modo compacto
  automático em terminal estreito, `:checkhealth` e `:help nvim-toolbar`.

## Instalação

Com [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "uesleinasch/nvim-toolbar",
  event = "VeryLazy",
  opts = {},
}
```

Requer Neovim 0.10 ou mais novo e `mouse` habilitado (`vim.o.mouse = "a"`).

## Configuração

```lua
require("nvim-toolbar").setup {
  position = "tabline", -- "tabline" ou "window"
  echo = true,          -- ecoar o atalho executado
  hover = true,         -- destacar o botão sob o mouse
  groups = nil,         -- nil usa o catálogo padrão; uma tabela o substitui
}
```

Comandos: `:ToolbarToggle`, `:ToolbarEnable`, `:ToolbarDisable`.
Ajuda: `:help nvim-toolbar` — inclui o formato dos itens para `groups` customizados.
Diagnóstico: `:checkhealth nvim-toolbar` — aponta `mouse` vazio, `showtabline` em 0,
tabline tomada por outro plugin, `position` inválida, terminal estreito demais e
`laststatus` que faz a barra custar uma linha extra.

## Onde a barra mora: `tabline` ou `window`

| | `position = "tabline"` | `position = "window"` |
|---|---|---|
| Linhas de tela | **1** | **2** (a barra e o separador de janelas) |
| Abas de buffer | substituídas pela barra | **preservadas** |
| Breadcrumbs (winbar) | preservados | preservados (migram para window-local) |
| Layout de janelas | intocado | ganha uma janela no topo |
| Clique | não mexe no foco | não mexe no foco (mappings globais de mouse) |

A segunda linha do modo `window` é inevitável: o Neovim sempre separa janelas
empilhadas por uma linha — statusline com `laststatus < 3`, `WinSeparator` com `3`. Ela
é pintada com a cor da barra, então lê como a borda inferior dela. Com
`laststatus = 3` (o padrão do AstroNvim) fica mais discreta, e o healthcheck avisa
quando não está.

A barra em janela é uma só: ao trocar de tabpage, ela migra junto. E quando o `:q`
fecha a última janela de código, a barra encerra junto — a sessão não fica presa
com uma barra órfã.

## Convivência com AstroNvim, heirline e bufferline

Nessas configurações a `tabline` já mostra as **abas de buffer** e a `winbar` os
breadcrumbs do LSP.

**Para manter as abas de buffer**, use a barra em janela:

```lua
{
  "uesleinasch/nvim-toolbar",
  event = "VeryLazy",
  opts = { position = "window" },
}
```

**Para a barra na tabline**, quem escreve em `vim.o.tabline` por último ganha, então
carregue depois do plugin de statusline:

```lua
{
  "uesleinasch/nvim-toolbar",
  dependencies = { "rebelot/heirline.nvim" },
  opts = { position = "tabline" },
}
```

Aí você perde as abas, mas não a navegação: o grupo **Arquivo** tem `:bn` próximo
arquivo, `:bp` anterior e `:bd` fecha.

## Aparência

Os destaques nascem ligados ao seu tema (`TabLine`, `TabLineSel`, `NormalFloat`,
`PmenuSel`), sem cor fixa. Para mudar, sobrescreva depois do `setup()`:

```lua
vim.api.nvim_set_hl(0, "ToolbarGroupOpen", { fg = "#111111", bg = "#7aa2f7", bold = true })
```

Grupos disponíveis: `ToolbarGroup`, `ToolbarGroupOpen`, `ToolbarGroupHover`,
`ToolbarAction`, `ToolbarActionHover`, `ToolbarSep`, `ToolbarFill`, `ToolbarMenu`,
`ToolbarMenuBorder`, `ToolbarMenuSel`, `ToolbarEcho`.

Em terminal estreito a barra entra em modo compacto sozinha (perde os `▾` e reduz as
ações a ícones) em vez de ser truncada — assim o `✕ Sair` nunca sai da tela.

## Experimentar sem tocar na sua config

```sh
nvim -u demo/init.lua demo/exemplo.txt
```

## Arquitetura

O modelo não sabe desenhar, o renderer não sabe executar, o executor não sabe de tela.

| Módulo | Responsabilidade |
|---|---|
| `catalog.lua` | Os grupos, itens e conjuntos de alvo. Dados puros. |
| `config.lua` | Defaults, `setup(opts)` e o acesso aos grupos efetivos. |
| `model.lua` | Resolve o item no modo atual: ação direta ou lista de alvos. |
| `context.lua` | Janela alvo e modo de quem acionou a barra. |
| `exec.lua` | Decide o plano (`gv`, `<Esc>`, teclas ou comando Ex) e o envia. |
| `actions.lua` | Orquestra resolver → restaurar contexto → executar → ecoar. |
| `echo.lua` | Monta a mensagem que ensina o atalho executado. |
| `menu.lua` | Dropdown e submenu em janela flutuante. |
| `render/buttons.lua` | Quais botões existem e seus rótulos, incluindo o modo compacto. |
| `render/init.lua` | Escolhe o renderer conforme `position`. |
| `render/tabline.lua` | Tabline com ids clicáveis via `%N@handler@`. |
| `render/window.lua` | Janela de uma linha no topo, com highlights por extmark. |
| `hover.lua` | Destaque do botão sob o mouse, delegando o hit-test ao renderer. |
| `highlights.lua` | Grupos de destaque linkados ao tema. |
| `health.lua` | O `:checkhealth nvim-toolbar`. |

As ações são enviadas com `nvim_feedkeys`, não com a API de buffer, para preservar
registradores, contadores, `.` e blocos de undo exatamente como o atalho digitado —
se o efeito divergisse do atalho ensinado, o eco seria uma mentira.

## Testes

```sh
make test        # unidade e integração, headless
make test-mouse  # cliques de mouse reais, dentro do tmux (requer tmux instalado)
```

Os testes usam [plenary.nvim](https://github.com/nvim-lua/plenary.nvim): se não for
encontrado no caminho do lazy.nvim, é clonado automaticamente em `.tests/`. Para
apontar outra cópia, use `PLENARY_DIR=/caminho make test`.

`make test-mouse` sobe um Neovim no tmux e injeta sequências SGR de mouse. Esse
caminho existe porque `nvim_input_mouse` exige UI atachada e um Neovim não sustenta ser
UI de outro (o canal RPC morre no `nvim_ui_attach`), e porque `nvim -l` não roda o loop
de input.

Três bugs que só esse teste pegou, e que passariam por qualquer suíte headless:

- O *release* do clique que abre o menu era herdado pelo menu recém-aberto, que
  escolhia o primeiro item sozinho. Daí o menu tratar `<LeftMouse>` e não
  `<LeftRelease>`.
- Com `winfixbuf` na janela da barra, um clique fazia o Neovim **abrir uma segunda
  janela** em vez de reusar a existente.
- O Neovim foca a barra ao terminar de iniciar (ela é a primeira janela do layout), e
  isso não passa por `WinEnter` — o guard de foco precisou escutar `VimEnter`/`UIEnter`.

## Perguntas frequentes

**Cliquei e nada aconteceu.**
`vim.o.mouse` precisa estar habilitado (`"a"`). Rode `:checkhealth nvim-toolbar` —
ele aponta essa e as outras causas comuns.

**Minhas abas de buffer sumiram.**
Com `position = "tabline"` a barra ocupa a tabline. Use `position = "window"` para
manter as abas do heirline/bufferline (veja a tabela acima).

**A barra some quando fecho o último arquivo com a árvore de arquivos aberta.**
É intencional: sem janela de código a barra não tem o que comandar, então sai do
caminho e volta sozinha quando um arquivo reaparece.

**Quero outros botões.**
Passe `groups` no `setup()` com o seu catálogo — o formato dos itens está em
`:help nvim-toolbar-opcoes-groups`.

**Funciona no meu Neovim?**
0.10 ou mais novo. O `setup()` avisa se a versão for mais antiga.

## Ainda não implementado

- `position = "float"` (a interface do renderer está pronta).
- Contagem de uso com sugestão de "graduar" para o teclado.
- Ícones nerdfont por item.
- Integração como provider do heirline.

## Contribuindo

Issues e PRs são bem-vindos — o [CONTRIBUTING.md](CONTRIBUTING.md) tem o setup,
como rodar os testes (`make test` e `make test-mouse`) e o que um PR precisa.
Bugs de clique/foco/janela quase sempre pedem um teste no harness de mouse real
(`tests/mouse/`), que roda dentro do tmux.

## Licença

[MIT](LICENSE).
