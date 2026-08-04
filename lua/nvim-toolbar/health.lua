local M = {}

function M.report()
  local out = {}

  if vim.o.mouse == "" then
    out[#out + 1] = {
      level = "error",
      message = "'mouse' esta vazio: nenhum clique chega na toolbar. Use vim.o.mouse = 'a'.",
    }
  end

  if vim.o.showtabline == 0 then
    out[#out + 1] = {
      level = "error",
      message = "'showtabline' esta 0: a barra nunca aparece. O setup() do plugin ajusta para 2.",
    }
  end

  if not vim.o.tabline:find "nvim%-toolbar" then
    out[#out + 1] = {
      level = "warn",
      message = "a tabline atual nao e do nvim-toolbar: outro plugin (heirline, bufferline) a tomou. "
        .. "Chame require('nvim-toolbar').setup() depois dele.",
    }
  end

  if not vim.o.mousemoveevent then
    out[#out + 1] = {
      level = "info",
      message = "'mousemoveevent' desligado: o destaque do botao sob o mouse fica indisponivel.",
    }
  end

  return out
end

function M.check()
  vim.health.start "nvim-toolbar"

  local problems = M.report()
  if #problems == 0 then
    vim.health.ok "toolbar no ar, mouse habilitado"
    return
  end

  for _, item in ipairs(problems) do
    if item.level == "error" then
      vim.health.error(item.message)
    elseif item.level == "warn" then
      vim.health.warn(item.message)
    else
      vim.health.info(item.message)
    end
  end
end

return M
