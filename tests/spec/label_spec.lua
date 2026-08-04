local model = require "nvim-toolbar.model"

describe("model.label", function()
  it("poe o atalho antes da descricao", function()
    assert.equals("y - Copia", model.label { keys = "y", label = "Copia" })
  end)

  it("mostra as duas teclas quando o item tem equivalente", function()
    assert.equals("d / x - Recorta", model.label { keys = "d", alias = "x", label = "Recorta" })
  end)

  it("encurta atalho de control para a forma que se le no teclado", function()
    assert.equals("^r - Refaz", model.label { keys = "<C-r>", label = "Refaz" })
  end)

  it("mostra o comando Ex como ele e digitado", function()
    assert.equals(":w - Salva", model.label { cmd = "write", display = ":w", label = "Salva" })
  end)

  it("cai no comando quando nao ha forma curta declarada", function()
    assert.equals(":nohlsearch - Limpa o destaque", model.label { cmd = "nohlsearch", label = "Limpa o destaque" })
  end)
end)
