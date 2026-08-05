local harness = require "tests.mouse.harness"

local SESSION = "toolbar-window-mouse"
local WINDOW = { position = "window", echo = false, hover = false }

local function menu_line(snap, pattern)
  for i, line in ipairs(snap.menu.lines) do
    if line:match(pattern) then return i end
  end
end

describe("clique de mouse na barra em janela dedicada", function()
  if not harness.available() then
    it("precisa do tmux para rodar", function() pending "tmux nao encontrado" end)
    return
  end

  after_each(function() harness.stop(SESSION) end)

  it("passar o mouse pela barra nao estoura erro de contexto", function()
    harness.start(SESSION, { "linha um", "linha dois" }, { position = "window", echo = false, hover = true })
    harness.wait(SESSION, "ready")
    local editar = harness.region(harness.read(SESSION, "regions"), "edit")

    harness.move(SESSION, 1, editar.col + 2)
    harness.move(SESSION, 1, editar.col + 3)
    vim.wait(800)

    local tela = harness.capture(SESSION)
    assert.is_nil(tela:find("E565", 1, true), "hover redesenhou a barra em contexto proibido")
    assert.is_nil(tela:find("Error executing lua", 1, true), "hover estourou erro de lua:\n" .. tela)
  end)

  it("abre o menu do grupo clicado", function()
    harness.start(SESSION, { "linha um", "linha dois", "linha tres" }, WINDOW)
    harness.wait(SESSION, "ready")
    local editar = harness.region(harness.read(SESSION, "regions"), "edit")

    harness.click(SESSION, 1, editar.col + 2)
    harness.wait(SESSION, "step1")

    local snap = harness.read(SESSION, "step1")
    assert.equals("window", snap.renderer)
    assert.is_true(snap.menu_open)
    assert.equals("edit", snap.group)
  end)

  it("nao deixa o foco preso na barra depois do clique", function()
    harness.start(SESSION, { "linha um", "linha dois" }, WINDOW)
    harness.wait(SESSION, "ready")
    local editar = harness.region(harness.read(SESSION, "regions"), "edit")

    harness.click(SESSION, 1, editar.col + 2)
    harness.wait(SESSION, "step1")

    assert.is_not.equals("nvimtoolbar", harness.read(SESSION, "step1").focus_filetype)
  end)

  it("executa a acao do item no buffer do codigo", function()
    harness.start(SESSION, { "linha um", "linha dois", "linha tres" }, WINDOW)
    harness.wait(SESSION, "ready")
    local editar = harness.region(harness.read(SESSION, "regions"), "edit")

    harness.click(SESSION, 1, editar.col + 2)
    harness.wait(SESSION, "step1")

    -- localiza o item na tela em vez de calcular bordas e offsets
    local item = harness.locate(SESSION, "dd - ")
    assert.is_not_nil(item, "item dd nao apareceu na tela")

    harness.click(SESSION, item.row, item.col)
    harness.wait(SESSION, "step2")

    local depois = harness.read(SESSION, "step2")
    assert.is_false(depois.menu_open)
    assert.same({ "linha dois", "linha tres" }, depois.lines)
  end)

  it("preserva a selecao visual, porque o clique na barra nao troca de janela", function()
    harness.start(SESSION, { "linha um", "linha dois", "linha tres" }, WINDOW)
    harness.wait(SESSION, "ready")
    local editar = harness.region(harness.read(SESSION, "regions"), "edit")

    harness.select_lines(SESSION, 2)
    harness.click(SESSION, 1, editar.col + 2)
    harness.wait(SESSION, "step1")
    local aberto = harness.read(SESSION, "step1")
    assert.equals("V", aberto.captured_mode)

    local copia = harness.locate(SESSION, "y - Copia  ▸")
    assert.is_not_nil(copia, "item de copia nao apareceu na tela")

    harness.click(SESSION, copia.row, copia.col)
    harness.wait(SESSION, "step2")

    assert.equals("linha um\nlinha dois\n", harness.read(SESSION, "step2").register)
  end)

  -- Clique na tabline chega com o winid da barra (primeira janela do layout) e
  -- winrow 0: sem o filtro de winrow no hit, clicar numa aba viraria clique na
  -- toolbar e a aba nunca receberia o clique.
  it("nao rouba o clique da tabline desenhada acima da barra", function()
    harness.start(
      SESSION,
      { "linha um", "linha dois" },
      { position = "window", echo = false, hover = false, showtabline = 2 }
    )
    harness.wait(SESSION, "ready")
    local regions = harness.read(SESSION, "regions")
    local arquivo = harness.region(regions, "file")
    local editar = harness.region(regions, "edit")

    local barra = harness.locate(SESSION, "Arquivo")
    assert.equals(2, barra.row, "com showtabline=2 a barra deveria descer para a linha 2")

    -- clique na tabline (linha 1), na coluna do botao Arquivo: nao pode abrir menu
    harness.click(SESSION, 1, arquivo.col + 2)
    vim.wait(1000)

    -- o primeiro menu a abrir deve ser o do clique de verdade na barra (linha 2)
    harness.click(SESSION, 2, editar.col + 2)
    harness.wait(SESSION, "step1")

    local snap = harness.read(SESSION, "step1")
    assert.is_true(snap.menu_open)
    assert.equals("edit", snap.group, "o clique na tabline abriu menu como se fosse na barra")
  end)

  it("desenha a barra na primeira linha da tela", function()
    harness.start(SESSION, { "linha um" }, WINDOW)
    harness.wait(SESSION, "ready")

    local barra = harness.locate(SESSION, "Arquivo")

    assert.is_not_nil(barra, "barra nao apareceu na tela")
    assert.equals(1, barra.row)
  end)

  -- O Neovim separa janelas empilhadas por uma linha (statusline com laststatus<3,
  -- WinSeparator com 3). Nao ha como evitar com split real: a barra custa duas
  -- linhas de tela. O teste fixa esse custo para ele nao crescer sem ninguem ver.
  it("custa exatamente duas linhas de tela: a barra e o separador", function()
    harness.start(SESSION, { "primeira linha do codigo" }, WINDOW)
    harness.wait(SESSION, "ready")

    local codigo = harness.locate(SESSION, "primeira linha do codigo")

    assert.is_not_nil(codigo, "codigo nao apareceu na tela")
    assert.equals(3, codigo.row)
  end)
end)
