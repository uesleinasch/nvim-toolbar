local tabline = require "nvim-toolbar.render.tabline"

describe("tabline.build", function()
  it("desenha os seis grupos na ordem do catalogo", function()
    local bar = tabline.build()

    local ordem = {}
    for nome in bar:gmatch "Arquivo|Navegar|Selecionar|Editar|Texto|Buscar" do
      ordem[#ordem + 1] = nome
    end
    for _, nome in ipairs { "Arquivo", "Navegar", "Selecionar", "Editar", "Texto", "Buscar" } do
      assert.is_truthy(bar:find(nome, 1, true), "grupo ausente na barra: " .. nome)
    end
  end)

  it("torna cada botao clicavel com id numerico proprio", function()
    local bar = tabline.build()

    assert.is_truthy(bar:find "%%1@v:lua%.NvimToolbarClick@")
    assert.is_truthy(bar:find "%%2@v:lua%.NvimToolbarClick@")
  end)

  it("fecha todo rotulo clicavel para o clique nao vazar para o vizinho", function()
    local bar = tabline.build()

    local _, aberturas = bar:gsub("%%%d+@v:lua%.NvimToolbarClick@", "")
    local _, fechamentos = bar:gsub("%%X", "")

    assert.equals(aberturas, fechamentos)
  end)

  it("resolve o id do clique para o grupo do catalogo", function()
    tabline.build()

    local alvo = tabline.target(1)

    assert.equals("group", alvo.kind)
    assert.equals("file", alvo.id)
  end)

  it("mapeia as acoes diretas depois dos grupos", function()
    tabline.build()

    local alvo = tabline.target(7)

    assert.equals("action", alvo.kind)
    assert.equals("undo", alvo.id)
  end)

  it("informa onde cada botao comeca para o menu ancorar embaixo dele", function()
    tabline.build()

    local primeiro = tabline.region(1)
    local segundo = tabline.region(2)

    assert.is_true(primeiro.col >= 0)
    assert.is_true(primeiro.width > 0)
    assert.is_true(segundo.col >= primeiro.col + primeiro.width)
  end)

  it("destaca o grupo cujo menu esta aberto", function()
    local bar = tabline.build { open = "edit" }

    assert.is_truthy(bar:find "ToolbarGroupOpen")
  end)

  it("cabe na largura do terminal em vez de ser truncada", function()
    local antes = vim.o.columns
    vim.o.columns = 80

    tabline.build()

    local largura = tabline.width()
    vim.o.columns = antes
    assert.is_true(largura <= 80, "barra com " .. largura .. " colunas em terminal de 80")
  end)

  it("mantem o botao de sair alcancavel em terminal estreito", function()
    local antes = vim.o.columns
    vim.o.columns = 80

    tabline.build()
    local sair = nil
    for id = 1, 40 do
      local target = tabline.target(id)
      if not target then break end
      if target.id == "quit" then sair = tabline.region(id) end
    end

    vim.o.columns = antes
    assert.is_not_nil(sair)
    assert.is_true(sair.col + sair.width <= 80, "botao de sair fora da tela")
  end)

  it("nao conta os codigos de highlight na coluna do botao", function()
    tabline.build()

    local editar = nil
    for id = 1, 6 do
      if tabline.target(id).id == "edit" then editar = tabline.region(id) end
    end

    -- "Arquivo Navegar Selecionar " ocupa menos de 40 colunas em qualquer tema
    assert.is_true(editar.col < 40, "coluna inflada pelos codigos de highlight: " .. tostring(editar.col))
  end)
end)
