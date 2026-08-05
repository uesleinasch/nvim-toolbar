local config = require "nvim-toolbar.config"
local hover = require "nvim-toolbar.hover"
local render = require "nvim-toolbar.render"
local tabline = require "nvim-toolbar.render.tabline"

describe("tabline.button_at", function()
  before_each(function() tabline.build() end)

  it("acha o botao pela coluna onde o mouse esta", function()
    local region = tabline.region(2)

    assert.equals(2, tabline.button_at(region.col + 2))
  end)

  it("nao acha botao no vao entre os grupos e as acoes diretas", function()
    local ultimo_grupo = tabline.region(6)

    assert.is_nil(tabline.button_at(ultimo_grupo.col + ultimo_grupo.width + 2))
  end)

  it("nao acha botao depois do fim da barra", function()
    assert.is_nil(tabline.button_at(tabline.width() + 3))
  end)

  it("so reconhece o mouse na linha da tabline", function()
    local region = tabline.region(2)

    assert.equals(2, tabline.hit { screenrow = 1, screencol = region.col + 2 })
    assert.is_nil(tabline.hit { screenrow = 7, screencol = region.col + 2 })
  end)
end)

describe("hover.handle", function()
  before_each(function()
    config.setup {}
    render.setup()
    tabline.build()
    hover.reset()
  end)

  after_each(function() render.teardown() end)

  it("marca o botao quando o mouse esta na linha da barra", function()
    local region = tabline.region(3)

    hover.handle { screenrow = 1, screencol = region.col + 2 }

    assert.equals(3, hover.current())
  end)

  it("limpa a marca quando o mouse desce para o texto", function()
    local region = tabline.region(3)
    hover.handle { screenrow = 1, screencol = region.col + 2 }

    hover.handle { screenrow = 8, screencol = region.col + 2 }

    assert.is_nil(hover.current())
  end)

  it("avisa so quando o botao sob o mouse muda, para nao redesenhar a cada pixel", function()
    local region = tabline.region(3)
    local avisos = 0
    hover.on_change = function() avisos = avisos + 1 end

    hover.handle { screenrow = 1, screencol = region.col + 1 }
    hover.handle { screenrow = 1, screencol = region.col + 2 }
    hover.handle { screenrow = 1, screencol = region.col + 3 }

    hover.on_change = nil
    assert.equals(1, avisos)
  end)
end)

describe("hover no renderer de janela", function()
  before_each(function()
    config.setup { position = "window" }
    render.setup()
    hover.reset()
  end)

  after_each(function() render.teardown() end)

  it("marca o botao pela janela da barra, nao pela linha da tela", function()
    local window = render.current()
    local region = window.region(2)

    hover.handle { winid = window.win(), winrow = 1, wincol = region.col + 1, screenrow = 1 }

    assert.equals(2, hover.current())
  end)

  it("limpa a marca quando o mouse esta em outra janela", function()
    local window = render.current()
    hover.handle { winid = window.win(), winrow = 1, wincol = window.region(2).col + 1, screenrow = 1 }

    hover.handle { winid = vim.api.nvim_get_current_win(), winrow = 3, wincol = 3, screenrow = 5 }

    assert.is_nil(hover.current())
  end)

  it("nao marca botao quando o mouse esta na tabline acima da barra", function()
    local window = render.current()

    hover.handle { winid = window.win(), winrow = 0, wincol = window.region(2).col + 1, screenrow = 1 }

    assert.is_nil(hover.current())
  end)
end)

describe("hover.setup e teardown", function()
  before_each(function() config.setup {} end)

  it("teardown remove o MouseMove e devolve a option como estava", function()
    local antes = vim.o.mousemoveevent

    hover.setup()
    assert.is_true(vim.o.mousemoveevent)
    assert.is_true(vim.fn.maparg("<MouseMove>", "n") ~= "")

    hover.teardown()

    assert.equals(antes, vim.o.mousemoveevent)
    assert.equals("", vim.fn.maparg("<MouseMove>", "n"))
  end)

  it("devolve o MouseMove que o usuario ja tinha", function()
    vim.keymap.set("n", "<MouseMove>", "<Nop>", { desc = "do usuario" })

    hover.setup()
    hover.teardown()

    local mapa = vim.fn.maparg("<MouseMove>", "n", false, true)
    pcall(vim.keymap.del, "n", "<MouseMove>")
    assert.equals("do usuario", mapa.desc)
  end)

  it("nao instala nada quando hover esta desligado na config", function()
    config.setup { hover = false }

    hover.setup()

    assert.equals("", vim.fn.maparg("<MouseMove>", "n"))
    hover.teardown()
  end)
end)

describe("tabline.build com hover", function()
  it("destaca o botao sob o mouse", function()
    local bar = tabline.build { hover = 2 }

    assert.is_truthy(bar:find "ToolbarGroupHover")
  end)

  it("deixa o grupo aberto com o destaque de aberto, nao de hover", function()
    local bar = tabline.build { open = "file", hover = 1 }

    assert.is_truthy(bar:find "ToolbarGroupOpen")
  end)
end)
