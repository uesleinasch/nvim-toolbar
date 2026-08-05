local config = require "nvim-toolbar.config"
local health = require "nvim-toolbar.health"

describe("health.report na barra em janela", function()
  after_each(function()
    config.setup()
    vim.o.laststatus = 3
  end)

  it("avisa que statusline por janela custa uma linha extra na barra", function()
    config.setup { position = "window" }
    vim.o.laststatus = 2

    local avisos = vim.tbl_filter(function(r) return r.level == "warn" end, health.report())

    local sobre = vim.tbl_filter(function(r) return r.message:find "laststatus" ~= nil end, avisos)
    assert.is_true(#sobre > 0)
  end)

  it("nao reclama de laststatus quando a barra esta na tabline", function()
    config.setup { position = "tabline" }
    vim.o.laststatus = 2

    local avisos = vim.tbl_filter(function(r) return r.message:find "laststatus" ~= nil end, health.report())

    assert.equals(0, #avisos)
  end)

  it("nao cobra a tabline de quem escolheu a barra em janela", function()
    config.setup { position = "window" }
    vim.o.tabline = "%!MinhaTabline()"

    local avisos = vim.tbl_filter(function(r) return r.message:find "tabline" ~= nil end, health.report())

    vim.o.tabline = ""
    assert.equals(0, #avisos)
  end)
end)

describe("health.report", function()
  it("reclama do mouse desligado, que e o que impede qualquer clique", function()
    local anterior = vim.o.mouse
    vim.o.mouse = ""

    local problemas = vim.tbl_filter(function(r) return r.level == "error" end, health.report())

    vim.o.mouse = anterior
    assert.is_true(#problemas > 0)
    assert.is_truthy(problemas[1].message:find "mouse")
  end)

  it("aprova quando o mouse esta habilitado e a barra esta no ar", function()
    local anterior = vim.o.mouse
    vim.o.mouse = "a"
    vim.o.tabline = "%!v:lua.require'nvim-toolbar'.render()"
    vim.o.showtabline = 2

    local problemas = vim.tbl_filter(function(r) return r.level == "error" end, health.report())

    vim.o.mouse = anterior
    assert.equals(0, #problemas)
  end)

  it("avisa quando o terminal e estreito demais para a barra caber", function()
    local antes = vim.o.columns
    vim.o.columns = 60

    local avisos = vim.tbl_filter(function(r) return r.level == "warn" end, health.report())

    vim.o.columns = antes
    local sobre_largura = vim.tbl_filter(function(r) return r.message:find "colunas" ~= nil end, avisos)
    assert.is_true(#sobre_largura > 0)
  end)

  it("avisa quando outro plugin tomou a tabline", function()
    vim.o.tabline = "%!HeirlineAlgumaCoisa()"

    local avisos = vim.tbl_filter(function(r) return r.level == "warn" end, health.report())

    assert.is_true(#avisos > 0)
    assert.is_truthy(avisos[1].message:find "tabline")
  end)
end)
