local buttons = require "nvim-toolbar.render.buttons"

describe("buttons.build", function()
  it("devolve um botao por grupo e um por acao direta, na ordem da barra", function()
    local list = buttons.build(200)

    local kinds = {}
    for _, button in ipairs(list) do
      if not button.separator then kinds[#kinds + 1] = button.kind .. ":" .. button.id end
    end

    assert.equals("group:file", kinds[1])
    assert.equals("group:search", kinds[6])
    assert.equals("action:undo", kinds[7])
    assert.equals("action:quit", kinds[#kinds])
  end)

  it("usa rotulo completo quando ha largura sobrando", function()
    local list = buttons.build(200)

    assert.is_truthy(list[1].text:find "▾")
  end)

  it("encurta os rotulos para caber em um terminal de 80 colunas", function()
    local list = buttons.build(80)

    assert.is_nil(list[1].text:find "▾")
    assert.is_true(buttons.width(list) <= 80, "compacto ainda ocupa " .. buttons.width(list))
  end)

  it("informa a largura minima que a barra precisa, para quem quiser avisar o usuario", function()
    assert.is_true(buttons.minimum_width() > 0)
    assert.is_true(buttons.minimum_width() <= 80)
  end)

  it("mede a largura somando o que cada botao ocupa na tela", function()
    local list = { { text = "abc" }, { text = " ▾ " } }

    assert.equals(6, buttons.width(list))
  end)

  it("marca o separador para o renderer decidir como desenhar", function()
    local list = buttons.build(200)

    local separadores = vim.tbl_filter(function(b) return b.separator end, list)

    assert.equals(1, #separadores)
  end)
end)
