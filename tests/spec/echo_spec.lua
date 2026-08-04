local echo = require "nvim-toolbar.echo"

describe("echo.message", function()
  it("mostra o atalho e o que ele fez", function()
    local msg = echo.message { keys = "yy", label = "Copia a linha inteira" }

    assert.equals("yy → Copia a linha inteira", msg)
  end)

  it("junta o operador com o alvo escolhido", function()
    local msg = echo.message { keys = "yiw", label = "a palavra", parent = { label = "Copia" } }

    assert.equals("yiw → Copia · a palavra", msg)
  end)

  it("avisa que falta completar o comando em vez de dizer que executou", function()
    local msg = echo.message { keys = ":%s/", label = "Substitui no arquivo...", pending = true }

    assert.equals(":%s/ → complete o comando e pressione Enter", msg)
  end)

  it("mostra o comando Ex do jeito que se digita", function()
    local msg = echo.message { cmd = "write", display = ":w", label = "Salva" }

    assert.equals(":w → Salva", msg)
  end)
end)
