local health = require "nvim-toolbar.health"

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

  it("avisa quando outro plugin tomou a tabline", function()
    vim.o.tabline = "%!HeirlineAlgumaCoisa()"

    local avisos = vim.tbl_filter(function(r) return r.level == "warn" end, health.report())

    assert.is_true(#avisos > 0)
    assert.is_truthy(avisos[1].message:find "tabline")
  end)
end)
