local toolbar = require "nvim-toolbar"
local menu = require "nvim-toolbar.menu"
local tabline = require "nvim-toolbar.render.tabline"

local function flush() vim.api.nvim_feedkeys("", "x", false) end

local function id_of(kind, id)
  tabline.build()
  for candidate = 1, 40 do
    local target = tabline.target(candidate)
    if not target then break end
    if target.kind == kind and target.id == id then return candidate end
  end
end

local function fresh_buffer(content)
  vim.cmd "enew!"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd "let &l:undolevels = &l:undolevels"
  return vim.api.nvim_get_current_buf()
end

describe("toolbar.setup", function()
  after_each(function()
    menu.close()
    toolbar.disable()
  end)

  it("assume a tabline e a deixa sempre visivel", function()
    toolbar.setup { echo = false }

    assert.is_truthy(vim.o.tabline:find("nvim-toolbar", 1, true))
    assert.equals(2, vim.o.showtabline)
  end)

  it("renderiza a barra com botoes clicaveis", function()
    toolbar.setup { echo = false }

    assert.is_truthy(toolbar.render():find("NvimToolbarClick", 1, true))
  end)

  it("devolve a tabline de antes quando e desligada", function()
    vim.o.tabline = "%!MinhaTablineAntiga()"

    toolbar.setup { echo = false }
    toolbar.disable()

    assert.equals("%!MinhaTablineAntiga()", vim.o.tabline)
  end)

  it("registra os comandos de usuario", function()
    toolbar.setup { echo = false }

    local commands = vim.api.nvim_get_commands {}
    assert.is_table(commands.ToolbarToggle)
    assert.is_table(commands.ToolbarEnable)
    assert.is_table(commands.ToolbarDisable)
  end)

  it("cria os destaques ligados ao tema em vez de cores fixas", function()
    toolbar.setup { echo = false }

    local hl = vim.api.nvim_get_hl(0, { name = "ToolbarGroup", link = true })

    assert.is_true(next(hl) ~= nil)
  end)

  it("setup de novo reconfigura de verdade em vez de ignorar", function()
    local render = require "nvim-toolbar.render"

    toolbar.setup { echo = false, position = "tabline" }
    toolbar.setup { echo = false, position = "window" }

    local nome = render.name()
    toolbar.disable()
    assert.equals("window", nome)
  end)

  it("desligar limpa os autocmds da barra", function()
    toolbar.setup { echo = false }
    assert.is_true(#vim.api.nvim_get_autocmds { group = "NvimToolbar" } > 0)

    toolbar.disable()

    local ok = pcall(vim.api.nvim_get_autocmds, { group = "NvimToolbar" })
    assert.is_false(ok, "o augroup deveria ter sido removido")
  end)

  it("devolve o clique de mouse que o usuario ja tinha ao desligar", function()
    vim.keymap.set("n", "<LeftMouse>", "<Nop>", { desc = "clique do usuario" })

    toolbar.setup { echo = false, position = "window" }
    toolbar.disable()

    local mapa = vim.fn.maparg("<LeftMouse>", "n", false, true)
    pcall(vim.keymap.del, "n", "<LeftMouse>")
    assert.equals("clique do usuario", mapa.desc)
  end)
end)

describe("clique na barra", function()
  before_each(function() toolbar.setup { echo = false } end)
  after_each(function()
    menu.close()
    toolbar.disable()
  end)

  it("abre o menu do grupo que foi clicado", function()
    _G.NvimToolbarClick(id_of("group", "edit"), 1, "l", "")

    assert.is_true(menu.is_open())
    assert.equals("edit", menu.open_group())
  end)

  it("fecha o menu quando o mesmo grupo e clicado de novo", function()
    local id = id_of("group", "edit")

    _G.NvimToolbarClick(id, 1, "l", "")
    _G.NvimToolbarClick(id, 1, "l", "")

    assert.is_false(menu.is_open())
  end)

  it("troca de menu quando outro grupo e clicado", function()
    _G.NvimToolbarClick(id_of("group", "edit"), 1, "l", "")
    _G.NvimToolbarClick(id_of("group", "text"), 1, "l", "")

    assert.is_true(menu.is_open())
    assert.equals("text", menu.open_group())
  end)

  it("executa a acao direta sem abrir menu", function()
    local buf = fresh_buffer { "um", "dois", "tres" }
    vim.api.nvim_feedkeys("dd", "x", false)

    _G.NvimToolbarClick(id_of("action", "undo"), 1, "l", "")
    flush()

    assert.is_false(menu.is_open())
    assert.same({ "um", "dois", "tres" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("ignora um id que nao existe em vez de estourar erro", function()
    assert.has_no.errors(function() _G.NvimToolbarClick(999, 1, "l", "") end)
  end)
end)
