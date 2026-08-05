local config = require "nvim-toolbar.config"
local render = require "nvim-toolbar.render"

describe("render", function()
  after_each(function()
    render.teardown()
    config.setup()
  end)

  it("usa o renderer de tabline por padrao", function()
    config.setup {}

    render.setup()

    assert.equals("tabline", render.name())
    assert.is_truthy(vim.o.tabline:find("nvim%-toolbar"))
  end)

  it("usa o renderer de janela quando a posicao pede", function()
    config.setup { position = "window" }

    render.setup()

    assert.equals("window", render.name())
    assert.is_not_nil(render.current().win())
  end)

  it("nao toca na tabline quando a barra vive numa janela", function()
    vim.o.tabline = "%!MinhaTablineAntiga()"
    config.setup { position = "window" }

    render.setup()

    assert.equals("%!MinhaTablineAntiga()", vim.o.tabline)
    vim.o.tabline = ""
  end)

  it("devolve o que mexeu ao ser desmontado", function()
    vim.o.tabline = "%!MinhaTablineAntiga()"
    config.setup {}
    render.setup()

    render.teardown()

    assert.equals("%!MinhaTablineAntiga()", vim.o.tabline)
    vim.o.tabline = ""
  end)

  it("cai no renderer de tabline se a posicao pedida nao existir", function()
    config.setup { position = "inventada" }

    render.setup()

    assert.equals("tabline", render.name())
  end)

  it("troca de renderer sem deixar rastro do anterior", function()
    config.setup { position = "window" }
    render.setup()
    local janela = render.current().win()

    render.teardown()
    config.setup { position = "tabline" }
    render.setup()

    assert.is_false(vim.api.nvim_win_is_valid(janela))
    assert.equals("tabline", render.name())
  end)
end)
