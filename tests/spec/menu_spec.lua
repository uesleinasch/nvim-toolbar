local menu = require "nvim-toolbar.menu"
local config = require "nvim-toolbar.config"

local function flush() vim.api.nvim_feedkeys("", "x", false) end

local function lines() return vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(menu.win()), 0, -1, false) end

local function index_of(keys)
  for i, item in ipairs(menu.items()) do
    if item.keys == keys then return i end
  end
end

local function fresh_buffer(content)
  vim.cmd "enew!"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  -- fecha o bloco de undo do preparo, senao um u desfaz preparo e acao juntos
  vim.cmd "let &l:undolevels = &l:undolevels"
  return vim.api.nvim_get_current_buf()
end

local function only_dashes(line) return line ~= "" and (line:gsub("─", "")) == "" end

describe("menu", function()
  before_each(function()
    config.setup { echo = false }
    menu.close()
    vim.cmd "only"
  end)

  after_each(function() menu.close() end)

  it("lista os itens do grupo com o atalho na frente da descricao", function()
    menu.open({ kind = "group", id = "edit" }, { col = 0 })

    assert.equals("y - Copia", vim.trim(lines()[1]):sub(1, 9))
  end)

  it("marca com uma seta os itens que ainda vao pedir o alvo", function()
    menu.open({ kind = "group", id = "edit" }, { col = 0 })

    assert.is_truthy(lines()[1]:find "▸")
  end)

  it("desenha o separador do catalogo como linha divisoria", function()
    menu.open({ kind = "group", id = "edit" }, { col = 0 })

    local tem_divisoria = false
    for _, line in ipairs(lines()) do
      if only_dashes(line) then tem_divisoria = true end
    end
    assert.is_true(tem_divisoria)
  end)

  it("ancora o menu na coluna do botao que o abriu", function()
    menu.open({ kind = "group", id = "edit" }, { col = 24 })

    assert.equals(24, vim.api.nvim_win_get_config(menu.win()).col)
  end)

  it("nao deixa o menu vazar da borda direita da tela", function()
    local largura = vim.o.columns

    menu.open({ kind = "group", id = "edit" }, { col = largura - 2 })

    local cfg = vim.api.nvim_win_get_config(menu.win())
    assert.is_true(cfg.col + cfg.width <= largura)
  end)

  it("troca para o submenu de alvos quando o item escolhido e um operador", function()
    menu.open({ kind = "group", id = "edit" }, { col = 0 })

    menu.choose(index_of "y")

    assert.is_true(menu.is_open())
    assert.equals("yy - a linha inteira", vim.trim(lines()[1]))
  end)

  it("executa e fecha quando o item nao precisa de alvo", function()
    local buf = fresh_buffer { "um", "dois", "tres" }
    menu.open({ kind = "group", id = "edit" }, { col = 0 })

    menu.choose(index_of "dd")
    flush()

    assert.is_false(menu.is_open())
    assert.same({ "dois", "tres" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("devolve o foco para o codigo depois de executar", function()
    local win = vim.api.nvim_get_current_win()
    fresh_buffer { "um", "dois" }
    menu.open({ kind = "group", id = "edit" }, { col = 0 })

    menu.choose(index_of "dd")
    flush()

    assert.equals(win, vim.api.nvim_get_current_win())
  end)

  it("fecha sem executar nada quando o usuario desiste", function()
    local buf = fresh_buffer { "um", "dois" }
    menu.open({ kind = "group", id = "edit" }, { col = 0 })

    menu.close()

    assert.is_false(menu.is_open())
    assert.same({ "um", "dois" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("reage ao pressionar o botao, nao ao soltar, para nao herdar o clique que abriu o menu", function()
    menu.open({ kind = "group", id = "edit" }, { col = 0 })
    local buf = vim.api.nvim_win_get_buf(menu.win())

    local lhs = vim.tbl_map(function(m) return m.lhs end, vim.api.nvim_buf_get_keymap(buf, "n"))

    assert.is_true(vim.tbl_contains(lhs, "<LeftMouse>"), "menu nao trata o pressionar do botao")
    assert.is_false(vim.tbl_contains(lhs, "<LeftRelease>"), "menu herda o soltar do clique que o abriu")
  end)

  it("nao anuncia mudanca ao fechar um menu que nem estava aberto", function()
    local avisos = 0
    menu.on_change = function() avisos = avisos + 1 end

    menu.close()

    menu.on_change = nil
    assert.equals(0, avisos)
  end)

  it("fecha o menu mesmo quando o comando do item falha", function()
    fresh_buffer { "modificado sem salvar" }
    menu.open({ kind = "group", id = "file" }, { col = 0 })

    local indice
    for i, item in ipairs(menu.items()) do
      if item.cmd == "bdelete" then indice = i end
    end

    assert.has_no.errors(function() menu.choose(indice) end)
    assert.is_false(menu.is_open())
  end)

  it("abre o grupo substituto quando a config troca o catalogo", function()
    config.setup { echo = false, groups = { { id = "meu", label = "Meu", items = { { keys = "p", label = "Cola" } } } } }

    menu.open({ kind = "group", id = "meu" }, { col = 0 })

    local aberto = menu.is_open()
    config.setup { echo = false }
    assert.is_true(aberto)
  end)

  it("executa a acao direta da barra sem abrir menu nenhum", function()
    local buf = fresh_buffer { "um", "dois", "tres" }
    vim.api.nvim_feedkeys("dd", "x", false)
    assert.same({ "dois", "tres" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))

    menu.invoke_action "undo"
    flush()

    assert.is_false(menu.is_open())
    assert.same({ "um", "dois", "tres" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)
end)
