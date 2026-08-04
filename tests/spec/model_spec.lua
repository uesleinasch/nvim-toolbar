local model = require "nvim-toolbar.model"

describe("model.resolve", function()
  it("executa o operador direto quando ha selecao visual", function()
    local item = { keys = "y", label = "Copia", targets = "operator" }

    local resolved = model.resolve(item, "V")

    assert.equals("action", resolved.kind)
    assert.equals("y", resolved.keys)
    assert.is_true(resolved.on_selection)
  end)

  it("pede o alvo quando o operador e acionado em modo normal", function()
    local item = { keys = "y", label = "Copia", targets = "operator" }

    local resolved = model.resolve(item, "n")

    assert.equals("targets", resolved.kind)
    assert.is_true(#resolved.items > 1)
  end)

  it("executa direto o item que nao precisa de alvo", function()
    local item = { keys = "p", label = "Cola depois" }

    local resolved = model.resolve(item, "n")

    assert.equals("action", resolved.kind)
    assert.equals("p", resolved.keys)
    assert.is_falsy(resolved.on_selection)
  end)
end)
