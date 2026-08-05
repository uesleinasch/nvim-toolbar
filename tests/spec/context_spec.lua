local context = require "nvim-toolbar.context"

local function open_float()
  local buf = vim.api.nvim_create_buf(false, true)
  return vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = 1,
    col = 1,
    width = 10,
    height = 2,
    style = "minimal",
  })
end

describe("context", function()
  before_each(function()
    vim.cmd "only"
    context.reset()
  end)

  it("guarda a janela e o modo de quem acionou a toolbar", function()
    local win = vim.api.nvim_get_current_win()

    local captured = context.capture()

    assert.equals(win, captured.win)
    assert.equals("n", captured.mode)
  end)

  it("mantem a janela do usuario como alvo mesmo se o clique vier de um flutuante", function()
    local user_win = vim.api.nvim_get_current_win()
    context.capture()

    local float = open_float()
    context.capture()

    assert.equals(user_win, context.state().win)
    vim.api.nvim_win_close(float, true)
  end)

  it("nunca elege a propria barra como janela alvo", function()
    local codigo = vim.api.nvim_get_current_win()
    context.capture()
    local barra_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[barra_buf].filetype = "nvimtoolbar"
    vim.cmd "topleft split"
    local barra = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(barra, barra_buf)

    context.capture()

    assert.equals(codigo, context.state().win)
    vim.api.nvim_win_close(barra, true)
  end)

  it("devolve o foco para a janela alvo", function()
    local user_win = vim.api.nvim_get_current_win()
    context.capture()
    local float = open_float()

    context.restore()

    assert.equals(user_win, vim.api.nvim_get_current_win())
    vim.api.nvim_win_close(float, true)
  end)

  it("sobrevive ao fechamento da janela alvo sem estourar erro", function()
    vim.cmd "split"
    context.capture()
    local alvo = context.state().win
    vim.api.nvim_win_close(alvo, true)

    assert.has_no.errors(function() context.restore() end)
  end)
end)
