# Contribuindo

Obrigado pelo interesse! Este guia cobre o essencial para desenvolver e enviar
mudanças.

## Preparando o ambiente

Requisitos: Neovim 0.10+, `git`, `make`. Para os testes de mouse, `tmux`. Para
formatação, [stylua](https://github.com/JohnnyMorganz/StyLua).

```sh
git clone https://github.com/uesleinasch/nvim-toolbar
cd nvim-toolbar
make test          # plenary.nvim é clonado em .tests/ na primeira execução
```

Para experimentar o plugin sem tocar na sua config:

```sh
nvim -u demo/init.lua demo/exemplo.txt
```

Para usar a sua cópia local na sua config (lazy.nvim):

```lua
{ dir = "/caminho/para/nvim-toolbar", opts = {} }
```

## Testes

```sh
make test          # unidade e integração, headless
make test-mouse    # cliques SGR reais dentro do tmux
```

- `PLENARY_DIR=/caminho make test` aponta para outro plenary.
- Todo bug corrigido precisa de um teste que **falhe sem a correção** — os
  specs em `tests/spec/` e `tests/mouse/` têm exemplos de ambos os estilos.
- Interação de mouse/foco/janela quase sempre precisa de um teste em
  `tests/mouse/` (headless não reproduz clique, foco de startup nem tabline).

## Estilo

- `make fmt` roda o stylua (config em `stylua.toml`). O CI falha se o código
  não estiver formatado.
- Comentário só para o que o código não consegue dizer (invariantes,
  acoplamentos não óbvios). Os arquivos existentes são a referência de tom.
- Textos visíveis ao usuário (labels, health, echo) em português, com acentos.

## Arquitetura em 30 segundos

O README tem a tabela completa. O resumo: `catalog` (dados) → `model`
(resolve item × modo) → `exec` (plano e execução) → `actions` (orquestra),
com `render/` (tabline ou janela) desenhando e `menu`/`hover`/`context`
cuidando da interação. O modelo não desenha, o renderer não executa.

## Enviando um PR

1. Crie um branch a partir da `main`.
2. Faça a mudança com teste.
3. Rode `make test`, `make test-mouse` e `make fmt`.
4. Atualize `CHANGELOG.md` se o usuário percebe a mudança.
5. Abra o PR preenchendo o template.

Mudanças grandes (renderer novo, mudança de interface pública): abra uma issue
antes para alinhar a direção — evita trabalho jogado fora.
