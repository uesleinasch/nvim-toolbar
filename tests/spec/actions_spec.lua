local actions = require "nvim-toolbar.actions"
local config = require "nvim-toolbar.config"

local function flush() vim.api.nvim_feedkeys("", "x", false) end

local function fresh_buffer(lines)
  vim.cmd "enew!"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  return vim.api.nvim_get_current_buf()
end

describe("config", function()
  it("nasce com a tabline como posicao e o eco ligado", function()
    config.setup()

    assert.equals("tabline", config.options.position)
    assert.is_true(config.options.echo)
  end)

  it("aceita o que o usuario passa sem perder o resto do default", function()
    config.setup { echo = false }

    assert.is_false(config.options.echo)
    assert.equals("tabline", config.options.position)
  end)
end)

describe("actions.invoke", function()
  before_each(function() config.setup { echo = false } end)

  it("executa o item que nao precisa de alvo", function()
    local buf = fresh_buffer { "um", "dois", "tres" }

    actions.invoke { keys = "dd", label = "Recorta a linha inteira" }
    flush()

    assert.same({ "dois", "tres" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("devolve os alvos em vez de executar quando o operador precisa de um", function()
    fresh_buffer { "um", "dois" }

    local resolved = actions.invoke { keys = "y", label = "Copia", targets = "operator" }

    assert.equals("targets", resolved.kind)
    assert.same({ "um", "dois" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("monta a mensagem de eco com o atalho que executou", function()
    fresh_buffer { "um" }

    local resolved = actions.invoke { keys = "yy", label = "Copia a linha inteira" }

    assert.equals("yy → Copia a linha inteira", resolved.echo)
  end)

  it("executa o alvo escolhido com as teclas compostas", function()
    local buf = fresh_buffer { "primeira palavra", "segunda" }
    vim.fn.setreg('"', "")

    local operador = { keys = "y", label = "Copia", targets = "operator" }
    local alvos = actions.invoke(operador)
    local palavra = vim.tbl_filter(function(t) return t.keys == "yiw" end, alvos.items)[1]
    actions.invoke(palavra)
    flush()

    assert.equals("primeira", vim.fn.getreg '"')
    assert.same({ "primeira palavra", "segunda" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)
end)
