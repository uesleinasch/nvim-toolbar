local harness = require "tests.mouse.harness"

local SESSION = "toolbar-mouse"

describe("clique de mouse de verdade", function()
  if not harness.available() then
    it("precisa do tmux para rodar", function() pending "tmux nao encontrado" end)
    return
  end

  after_each(function() harness.stop(SESSION) end)

  it("abre o menu do grupo clicado na barra", function()
    local dir = harness.start(SESSION, { "linha um", "linha dois", "linha tres" })
    harness.wait "toolbar-ready"
    local regions = harness.read(dir .. "/regions.json")
    local editar = harness.region(regions, "edit")

    harness.click(SESSION, 1, editar.col + 2)
    harness.wait "toolbar-step1"

    local snap = harness.read(dir .. "/step1.json")
    assert.is_true(snap.menu_open)
    assert.equals("edit", snap.group)
    assert.is_truthy(snap.menu.lines[1]:find("y - Copia", 1, true))
  end)

  it("executa a acao ao clicar no item do menu, sem tocar no teclado", function()
    local dir = harness.start(SESSION, { "linha um", "linha dois", "linha tres" })
    harness.wait "toolbar-ready"
    local regions = harness.read(dir .. "/regions.json")
    local editar = harness.region(regions, "edit")

    harness.click(SESSION, 1, editar.col + 2)
    harness.wait "toolbar-step1"
    local aberto = harness.read(dir .. "/step1.json")

    local alvo = nil
    for i, line in ipairs(aberto.menu.lines) do
      if line:find("dd - ", 1, true) then alvo = i end
    end
    assert.is_not_nil(alvo, "item dd nao encontrado no menu")

    -- borda de cima ocupa uma linha; conteudo comeca na linha de tela row+2
    harness.click(SESSION, aberto.menu.row + 1 + alvo, aberto.menu.col + 2)
    harness.wait "toolbar-step2"

    local depois = harness.read(dir .. "/step2.json")
    assert.is_false(depois.menu_open)
    assert.same({ "linha dois", "linha tres" }, depois.lines)
  end)

  it("copia a selecao direto, sem perguntar o alvo, quando ha texto selecionado", function()
    local dir = harness.start(SESSION, { "linha um", "linha dois", "linha tres" })
    harness.wait "toolbar-ready"
    local regions = harness.read(dir .. "/regions.json")
    local editar = harness.region(regions, "edit")

    harness.select_lines(SESSION, 2)
    harness.click(SESSION, 1, editar.col + 2)
    harness.wait "toolbar-step1"
    local aberto = harness.read(dir .. "/step1.json")

    local copia = nil
    for i, line in ipairs(aberto.menu.lines) do
      -- ancorado no inicio: "yy - Copia a linha inteira" tambem contem "y - Copia"
      if not copia and line:match "^%s*y %- Copia" then copia = i end
    end
    assert.is_not_nil(copia, "item de copia nao encontrado")

    harness.click(SESSION, aberto.menu.row + 1 + copia, aberto.menu.col + 2)
    harness.wait "toolbar-step2"

    local depois = harness.read(dir .. "/step2.json")
    assert.is_false(depois.menu_open, "menu pediu alvo mesmo havendo selecao")
    assert.equals("linha um\nlinha dois\n", depois.register)
    assert.same({ "linha um", "linha dois", "linha tres" }, depois.lines)
  end)

  it("clicar de novo no mesmo grupo fecha o menu", function()
    local dir = harness.start(SESSION, { "linha um", "linha dois" })
    harness.wait "toolbar-ready"
    local regions = harness.read(dir .. "/regions.json")
    local navegar = harness.region(regions, "move")

    harness.click(SESSION, 1, navegar.col + 2)
    harness.wait "toolbar-step1"
    harness.click(SESSION, 1, navegar.col + 2)
    harness.wait "toolbar-step2"

    local snap = harness.read(dir .. "/step2.json")
    assert.is_false(snap.menu_open)
  end)
end)
