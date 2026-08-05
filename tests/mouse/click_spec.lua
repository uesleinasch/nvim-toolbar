local harness = require "tests.mouse.harness"

local SESSION = "toolbar-tabline-mouse"

local function menu_line(snap, pattern)
  for i, line in ipairs(snap.menu.lines) do
    if line:match(pattern) then return i end
  end
end

describe("clique de mouse na tabline", function()
  if not harness.available() then
    it("precisa do tmux para rodar", function() pending "tmux nao encontrado" end)
    return
  end

  after_each(function() harness.stop(SESSION) end)

  it("passar o mouse pela barra nao estoura erro de contexto", function()
    harness.start(SESSION, { "linha um", "linha dois" }, { echo = false, hover = true })
    harness.wait(SESSION, "ready")
    local editar = harness.region(harness.read(SESSION, "regions"), "edit")

    harness.move(SESSION, 1, editar.col + 2)
    harness.move(SESSION, 1, editar.col + 3)
    vim.wait(800)

    local tela = harness.capture(SESSION)
    assert.is_nil(tela:find("E565", 1, true), "hover redesenhou a barra em contexto proibido")
    assert.is_nil(tela:find("Error executing lua", 1, true), "hover estourou erro de lua:\n" .. tela)
  end)

  it("abre o menu do grupo clicado na barra", function()
    harness.start(SESSION, { "linha um", "linha dois", "linha tres" })
    harness.wait(SESSION, "ready")
    local editar = harness.region(harness.read(SESSION, "regions"), "edit")

    harness.click(SESSION, 1, editar.col + 2)
    harness.wait(SESSION, "step1")

    local snap = harness.read(SESSION, "step1")
    assert.equals("tabline", snap.renderer)
    assert.is_true(snap.menu_open)
    assert.equals("edit", snap.group)
    assert.is_truthy(snap.menu.lines[1]:find("y - Copia", 1, true))
  end)

  it("executa a acao ao clicar no item do menu, sem tocar no teclado", function()
    harness.start(SESSION, { "linha um", "linha dois", "linha tres" })
    harness.wait(SESSION, "ready")
    local editar = harness.region(harness.read(SESSION, "regions"), "edit")

    harness.click(SESSION, 1, editar.col + 2)
    harness.wait(SESSION, "step1")
    local aberto = harness.read(SESSION, "step1")

    local alvo = menu_line(aberto, "^%s*dd %- ")
    assert.is_not_nil(alvo, "item dd nao encontrado no menu")

    -- a borda de cima ocupa uma linha; o conteudo comeca em row + 2
    harness.click(SESSION, aberto.menu.row + 1 + alvo, aberto.menu.col + 2)
    harness.wait(SESSION, "step2")

    local depois = harness.read(SESSION, "step2")
    assert.is_false(depois.menu_open)
    assert.same({ "linha dois", "linha tres" }, depois.lines)
  end)

  it("copia a selecao direto, sem perguntar o alvo, quando ha texto selecionado", function()
    harness.start(SESSION, { "linha um", "linha dois", "linha tres" })
    harness.wait(SESSION, "ready")
    local editar = harness.region(harness.read(SESSION, "regions"), "edit")

    harness.select_lines(SESSION, 2)
    harness.click(SESSION, 1, editar.col + 2)
    harness.wait(SESSION, "step1")
    local aberto = harness.read(SESSION, "step1")

    -- ancorado no inicio: "yy - Copia a linha inteira" tambem contem "y - Copia"
    local copia = menu_line(aberto, "^%s*y %- Copia")
    assert.is_not_nil(copia, "item de copia nao encontrado")

    harness.click(SESSION, aberto.menu.row + 1 + copia, aberto.menu.col + 2)
    harness.wait(SESSION, "step2")

    local depois = harness.read(SESSION, "step2")
    assert.is_false(depois.menu_open, "menu pediu alvo mesmo havendo selecao")
    assert.equals("linha um\nlinha dois\n", depois.register)
    assert.same({ "linha um", "linha dois", "linha tres" }, depois.lines)
  end)

  it("clicar de novo no mesmo grupo fecha o menu", function()
    harness.start(SESSION, { "linha um", "linha dois" })
    harness.wait(SESSION, "ready")
    local navegar = harness.region(harness.read(SESSION, "regions"), "move")

    harness.click(SESSION, 1, navegar.col + 2)
    harness.wait(SESSION, "step1")
    harness.click(SESSION, 1, navegar.col + 2)
    harness.wait(SESSION, "step2")

    assert.is_false(harness.read(SESSION, "step2").menu_open)
  end)
end)
