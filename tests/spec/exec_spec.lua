local exec = require "nvim-toolbar.exec"
local model = require "nvim-toolbar.model"

local function flush() vim.api.nvim_feedkeys("", "x", false) end

local function fresh_buffer(lines)
  vim.cmd "enew!"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  return vim.api.nvim_get_current_buf()
end

describe("exec.plan", function()
  it("manda as teclas direto quando nao ha selecao envolvida", function()
    local plan = exec.plan({ kind = "action", keys = "dd" }, { mode = "n" })

    assert.equals("dd", plan.keys)
    assert.is_nil(plan.cmd)
  end)

  it("restaura a selecao antes do operador quando o visual ja terminou", function()
    local plan = exec.plan({ kind = "action", keys = "y", on_selection = true }, { mode = "n" })

    assert.equals("gvy", plan.keys)
  end)

  it("nao reaplica gv enquanto o visual esta ativo", function()
    local plan = exec.plan({ kind = "action", keys = "y", on_selection = true }, { mode = "V" })

    assert.equals("y", plan.keys)
  end)

  it("sai do Insert antes de um comando de modo normal", function()
    local plan = exec.plan({ kind = "action", keys = "dd", modes = { "n" } }, { mode = "i" })

    assert.equals("<Esc>dd", plan.keys)
  end)

  it("sai do visual quando o item so funciona em normal", function()
    local plan = exec.plan({ kind = "action", keys = ":%s/", modes = { "n" }, pending = true }, { mode = "V" })

    assert.equals("<Esc>:%s/", plan.keys)
  end)

  it("passa o comando Ex adiante em vez de teclas", function()
    local plan = exec.plan({ kind = "action", cmd = "write" }, { mode = "n" })

    assert.equals("write", plan.cmd)
    assert.is_nil(plan.keys)
  end)
end)

describe("exec.run", function()
  it("apaga a linha de verdade no buffer", function()
    local buf = fresh_buffer { "um", "dois", "tres" }

    exec.run(model.resolve({ keys = "dd", label = "Recorta a linha" }, "n"))
    flush()

    assert.same({ "dois", "tres" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("copia a selecao restaurada quando o menu havia tirado o visual", function()
    local buf = fresh_buffer { "um", "dois", "tres" }
    vim.api.nvim_feedkeys("ggVj", "x", false)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.fn.setreg('"', "")

    exec.run { kind = "action", keys = "y", label = "Copia", on_selection = true }
    flush()

    assert.equals("um\ndois\n", vim.fn.getreg '"')
    assert.same({ "um", "dois", "tres" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("executa o comando Ex declarado", function()
    local buf = fresh_buffer { "um", "dois", "tres" }

    exec.run { kind = "action", cmd = "2delete", label = "Recorta a linha 2" }
    flush()

    assert.same({ "um", "tres" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("nao insere texto no arquivo quando o clique vem do modo Insert", function()
    local buf = fresh_buffer { "um", "dois" }
    vim.api.nvim_feedkeys("i", "x", false)

    exec.run { kind = "action", keys = "dd", label = "Recorta a linha", modes = { "n" } }
    flush()

    assert.same({ "dois" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.equals("n", vim.fn.mode(1))
  end)
end)
