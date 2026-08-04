local hover = require "nvim-toolbar.hover"
local tabline = require "nvim-toolbar.render.tabline"

describe("hover.button_at", function()
  before_each(function()
    tabline.build()
    hover.reset()
  end)

  it("acha o botao pela coluna onde o mouse esta", function()
    local region = tabline.region(2)

    local id = hover.button_at(region.col + 2)

    assert.equals(2, id)
  end)

  it("nao acha botao no vao entre os grupos e as acoes diretas", function()
    local ultimo_grupo = tabline.region(6)

    local id = hover.button_at(ultimo_grupo.col + ultimo_grupo.width + 2)

    assert.is_nil(id)
  end)

  it("nao acha botao depois do fim da barra", function()
    local id = hover.button_at(tabline.width() + 3)

    assert.is_nil(id)
  end)
end)

describe("hover.handle", function()
  before_each(function()
    tabline.build()
    hover.reset()
  end)

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
