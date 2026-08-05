local window = require "nvim-toolbar.render.window"

local function toolbar_lines()
  return vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(window.win()), 0, -1, false)
end

describe("render/window", function()
  before_each(function()
    window.teardown()
    vim.cmd "only"
  end)

  after_each(function()
    window.teardown()
    if #vim.api.nvim_list_tabpages() > 1 then vim.cmd "tabonly" end
  end)

  it("abre uma janela de uma linha no topo da tela", function()
    window.setup()

    local config = vim.api.nvim_win_get_config(window.win())
    assert.equals(1, vim.api.nvim_win_get_height(window.win()))
    assert.equals("", config.relative, "a barra deve ser uma janela real, nao flutuante")
    assert.equals(1, vim.fn.win_screenpos(window.win())[1])
  end)

  it("desenha os grupos e as acoes numa unica linha", function()
    window.setup()
    window.render {}

    local lines = toolbar_lines()
    assert.equals(1, #lines)
    assert.is_truthy(lines[1]:find("Arquivo", 1, true))
    assert.is_truthy(lines[1]:find("Buscar", 1, true))
  end)

  it("nao deixa o usuario editar nem trocar o buffer da barra", function()
    window.setup()

    local buf = vim.api.nvim_win_get_buf(window.win())
    assert.is_false(vim.bo[buf].modifiable)
    assert.equals("nofile", vim.bo[buf].buftype)
    assert.is_true(vim.wo[window.win()].winfixheight)
    assert.equals("nvimtoolbar", vim.bo[buf].filetype)
  end)

  it("nao herda numeros de linha do resto da config", function()
    vim.o.number = true

    window.setup()

    assert.is_false(vim.wo[window.win()].number)
  end)

  it("nao gasta uma linha extra com winbar quando a config tem winbar global", function()
    vim.o.winbar = "%f"

    window.setup()

    local altura = vim.api.nvim_win_get_height(window.win())
    local efetivo = vim.api.nvim_get_option_value("winbar", { win = window.win() })
    window.teardown()
    vim.o.winbar = ""
    assert.equals("", efetivo)
    assert.equals(1, altura, "winbar global roubou uma linha da barra")
  end)

  it("preserva o winbar das janelas de codigo ao assumir o global", function()
    vim.o.winbar = "%f"
    local codigo = vim.api.nvim_get_current_win()

    window.setup()

    local no_codigo = vim.api.nvim_get_option_value("winbar", { win = codigo })
    window.teardown()
    vim.o.winbar = ""
    assert.equals("%f", no_codigo)
  end)

  it("aplica o winbar tambem nas janelas de codigo abertas depois", function()
    vim.o.winbar = "%f"
    window.setup()

    vim.cmd "split"
    local nova = vim.api.nvim_get_current_win()

    local no_novo = vim.api.nvim_get_option_value("winbar", { win = nova })
    window.teardown()
    vim.o.winbar = ""
    assert.equals("%f", no_novo)
  end)

  it("devolve o winbar global no teardown", function()
    vim.o.winbar = "%f"
    window.setup()

    window.teardown()

    local restaurado = vim.o.winbar
    vim.o.winbar = ""
    assert.equals("%f", restaurado)
  end)

  it("nao usa winfixbuf, que faz o clique abrir uma janela fantasma", function()
    window.setup()

    assert.is_false(vim.wo[window.win()].winfixbuf)
  end)

  it("devolve o foco ao codigo se alguem entrar na barra", function()
    window.setup()
    local codigo = vim.api.nvim_get_current_win()

    vim.api.nvim_set_current_win(window.win())
    vim.wait(200, function() return vim.api.nvim_get_current_win() ~= window.win() end, 10)

    assert.equals(codigo, vim.api.nvim_get_current_win())
  end)

  it("devolve o foco tambem quando o Neovim entra na barra pela inicializacao", function()
    window.setup()
    local codigo = vim.api.nvim_get_current_win()
    -- a barra e a primeira janela do layout; o Neovim pode focar nela ao terminar
    -- de iniciar, e isso nao passa por WinEnter
    vim.api.nvim_win_call(window.win(), function() end)
    vim.cmd(("noautocmd call win_gotoid(%d)"):format(window.win()))
    assert.equals(window.win(), vim.api.nvim_get_current_win())

    vim.api.nvim_exec_autocmds("VimEnter", {})
    vim.wait(200, function() return vim.api.nvim_get_current_win() ~= window.win() end, 10)

    assert.equals(codigo, vim.api.nvim_get_current_win())
  end)

  it("nao cria uma segunda janela de barra quando o foco passa por ela", function()
    window.setup()

    vim.api.nvim_set_current_win(window.win())
    vim.wait(200, function() return vim.api.nvim_get_current_win() ~= window.win() end, 10)

    local barras = 0
    for _, candidate in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(candidate)].filetype == "nvimtoolbar" then barras = barras + 1 end
    end
    assert.equals(1, barras)
  end)

  it("nao rouba o foco ao ser criada", function()
    local antes = vim.api.nvim_get_current_win()

    window.setup()

    assert.equals(antes, vim.api.nvim_get_current_win())
  end)

  it("colore cada botao com o seu destaque", function()
    window.setup()
    window.render { open = "edit" }

    local buf = vim.api.nvim_win_get_buf(window.win())
    local marks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })

    local grupos = vim.tbl_map(function(m) return m[4].hl_group end, marks)
    assert.is_true(vim.tbl_contains(grupos, "ToolbarGroupOpen"))
    assert.is_true(vim.tbl_contains(grupos, "ToolbarGroup"))
  end)

  it("acha o botao pela coluna clicada dentro da janela", function()
    window.setup()
    window.render {}

    local primeiro = window.region(1)
    local segundo = window.region(2)

    assert.equals(1, window.button_at(primeiro.col + 1))
    assert.equals(2, window.button_at(segundo.col + 1))
  end)

  it("so reconhece o clique quando ele cai na janela da barra", function()
    window.setup()
    window.render {}
    local outra = vim.api.nvim_get_current_win()

    assert.equals(1, window.hit { winid = window.win(), winrow = 1, wincol = window.region(1).col + 1 })
    assert.is_nil(window.hit { winid = outra, winrow = 1, wincol = 1 })
  end)

  it("ignora o clique na tabline, que chega com o winid da barra e winrow 0", function()
    window.setup()
    window.render {}

    assert.is_nil(window.hit { winid = window.win(), winrow = 0, wincol = window.region(1).col + 1 })
  end)

  it("resolve o id do clique para o grupo do catalogo", function()
    window.setup()
    window.render {}

    assert.equals("group", window.target(1).kind)
    assert.equals("file", window.target(1).id)
  end)

  it("fecha a janela e limpa o estado no teardown", function()
    window.setup()
    local win = window.win()

    window.teardown()

    assert.is_false(vim.api.nvim_win_is_valid(win))
    assert.is_nil(window.win())
  end)

  it("encerra a barra quando o quit fecha a ultima janela de codigo", function()
    window.setup()
    local bar = window.win()
    local codigo = vim.api.nvim_get_current_win()
    vim.cmd "tabnew"

    -- reproduz o :q na janela de codigo: QuitPre dispara e so depois a janela fecha
    vim.api.nvim_win_call(codigo, function() vim.api.nvim_exec_autocmds("QuitPre", {}) end)
    vim.api.nvim_win_close(codigo, true)
    vim.wait(200, function() return not vim.api.nvim_win_is_valid(bar) end, 10)

    assert.is_false(vim.api.nvim_win_is_valid(bar))
  end)

  it("mantem a barra quando o quit deixa outra janela de codigo aberta", function()
    window.setup()
    vim.cmd "split"
    local extra = vim.api.nvim_get_current_win()

    vim.api.nvim_exec_autocmds("QuitPre", {})
    vim.api.nvim_win_close(extra, true)
    vim.wait(100)

    assert.is_true(vim.api.nvim_win_is_valid(window.win()))
  end)

  it("mantem a barra quando o usuario cancela o quit", function()
    window.setup()

    -- QuitPre dispara mesmo quando o :confirm q e cancelado e nada fecha
    vim.api.nvim_exec_autocmds("QuitPre", {})
    vim.wait(100)

    assert.is_true(vim.api.nvim_win_is_valid(window.win()))
  end)

  it("recria a janela se algo a fechar por fora", function()
    window.setup()
    vim.api.nvim_win_close(window.win(), true)

    window.render {}

    assert.is_true(window.win() ~= nil and vim.api.nvim_win_is_valid(window.win()))
  end)

  it("migra para a tabpage atual em vez de ficar orfa na anterior", function()
    window.setup()
    vim.cmd "tabnew"

    window.render {}

    assert.equals(vim.api.nvim_get_current_tabpage(), vim.api.nvim_win_get_tabpage(window.win()))
  end)
end)
