local catalog = require "nvim-toolbar.catalog"

local function all_items()
  local items = {}
  for _, group in ipairs(catalog.groups) do
    for _, item in ipairs(group.items) do
      if not item.separator then items[#items + 1] = item end
    end
  end
  return items
end

describe("catalog.groups", function()
  it("expoe os seis grupos na ordem da barra", function()
    local labels = vim.tbl_map(function(g) return g.label end, catalog.groups)

    assert.same({ "Arquivo", "Navegar", "Selecionar", "Editar", "Texto", "Buscar" }, labels)
  end)

  it("da um id estavel a cada grupo", function()
    local seen = {}
    for _, group in ipairs(catalog.groups) do
      assert.is_string(group.id)
      assert.is_nil(seen[group.id], "id de grupo repetido: " .. tostring(group.id))
      seen[group.id] = true
    end
  end)

  it("nao deixa item sem acao nem sem descricao", function()
    for _, item in ipairs(all_items()) do
      assert.is_true(item.keys ~= nil or item.cmd ~= nil, "item sem keys nem cmd: " .. tostring(item.label))
      assert.is_string(item.label)
      assert.is_true(#item.label > 0)
    end
  end)

  it("so aponta para conjuntos de alvo que existem", function()
    for _, item in ipairs(all_items()) do
      if item.targets then
        assert.is_table(catalog.targets[item.targets], "conjunto de alvo inexistente: " .. tostring(item.targets))
      end
    end
  end)

  it("cobre os operadores que precisam de alvo", function()
    local com_alvo = {}
    for _, item in ipairs(all_items()) do
      if item.targets then com_alvo[item.keys] = true end
    end

    for _, keys in ipairs { "y", "d", "c", "=", "gu", "gU", "g~" } do
      assert.is_true(com_alvo[keys] == true, "operador sem conjunto de alvo: " .. keys)
    end
  end)
end)

describe("catalog.actions", function()
  it("mantem na barra as acoes de uso constante", function()
    local labels = vim.tbl_map(function(a) return a.label end, catalog.actions)

    assert.same({ "Desfaz", "Refaz", "Salva", "Normal", "Sair" }, labels)
  end)

  it("sai pedindo confirmacao para nao perder trabalho", function()
    local sair = catalog.actions[#catalog.actions]

    assert.equals("confirm qa", sair.cmd)
  end)
end)
