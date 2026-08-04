# nvim-toolbar

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

## Instalação

Com [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "nvim-toolbar",
  event = "VeryLazy",
  opts = {},
}
```

Requer Neovim 0.11 ou mais novo e `mouse` habilitado (`vim.o.mouse = "a"`).

## Configuração

```lua
require("nvim-toolbar").setup {
  position = "tabline", -- onde a barra é desenhada
  echo = true,          -- ecoar o atalho executado
  hover = true,         -- destacar o botão sob o mouse
  groups = nil,         -- nil usa o catálogo padrão; uma tabela o substitui
}
```

Comandos: `:ToolbarToggle`, `:ToolbarEnable`, `:ToolbarDisable`.
Diagnóstico: `:checkhealth nvim-toolbar` — aponta `mouse` vazio, `showtabline` em 0 e
tabline tomada por outro plugin.

## Convivência com AstroNvim, heirline e bufferline

A barra ocupa a `tabline`, que nessas configurações costuma mostrar as **abas de
buffer**. Quem escreve em `vim.o.tabline` por último ganha, então chame o `setup()`
depois do plugin de statusline:

```lua
{
  "nvim-toolbar",
  dependencies = { "rebelot/heirline.nvim" },
  opts = {},
}
```

Você perde as abas de buffer, mas não a navegação: o grupo **Arquivo** tem
`:bn` próximo arquivo, `:bp` anterior e `:bd` fecha. Se preferir manter as abas, o
renderer de janela dedicada (`position = "window"`) resolve o conflito — ainda não
implementado, veja abaixo.

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
| `model.lua` | Resolve o item no modo atual: ação direta ou lista de alvos. |
| `context.lua` | Janela alvo e modo de quem acionou a barra. |
| `exec.lua` | Decide o plano (`gv`, `<Esc>`, teclas ou comando Ex) e o envia. |
| `actions.lua` | Orquestra resolver → restaurar contexto → executar → ecoar. |
| `menu.lua` | Dropdown e submenu em janela flutuante. |
| `render/tabline.lua` | Monta a tabline com os ids clicáveis e mede as colunas. |
| `hover.lua` | Destaque do botão sob o mouse. |

As ações são enviadas com `nvim_feedkeys`, não com a API de buffer, para preservar
registradores, contadores, `.` e blocos de undo exatamente como o atalho digitado —
se o efeito divergisse do atalho ensinado, o eco seria uma mentira.

## Testes

```sh
make test        # unidade e integração, headless
make test-mouse  # cliques de mouse reais, dentro do tmux
```

`make test-mouse` sobe um Neovim no tmux e injeta sequências SGR de mouse. Esse
caminho existe porque `nvim_input_mouse` exige UI atachada e um Neovim não sustenta ser
UI de outro (o canal RPC morre no `nvim_ui_attach`), e porque `nvim -l` não roda o loop
de input. Foi esse teste que pegou o bug em que o *release* do clique de abertura era
herdado pelo menu, escolhendo o primeiro item sozinho.

## Ainda não implementado

- `position = "window"` e `position = "float"` (a interface do renderer está pronta).
- Contagem de uso com sugestão de "graduar" para o teclado.
- Ícones nerdfont por item.
- Integração como provider do heirline.
