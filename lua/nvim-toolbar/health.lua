local buttons = require "nvim-toolbar.render.buttons"
local config = require "nvim-toolbar.config"

local M = {}

function M.report()
  local out = {}
  local position = config.options.position
  local in_window = position == "window"

  if position ~= "tabline" and position ~= "window" then
    out[#out + 1] = {
      level = "error",
      message = ("'position' = %q não existe: use \"tabline\" ou \"window\". A barra caiu em \"tabline\"."):format(
        tostring(position)
      ),
    }
  end

  if vim.o.mouse == "" then
    out[#out + 1] = {
      level = "error",
      message = "'mouse' está vazio: nenhum clique chega na toolbar. Use vim.o.mouse = 'a'.",
    }
  end

  if not in_window and vim.o.showtabline == 0 then
    out[#out + 1] = {
      level = "error",
      message = "'showtabline' está 0: a barra nunca aparece. O setup() do plugin ajusta para 2.",
    }
  end

  local minimum = buttons.minimum_width()
  if vim.o.columns < minimum then
    out[#out + 1] = {
      level = "warn",
      message = ("terminal com %d colunas: a barra precisa de %d colunas mesmo compacta, "):format(
        vim.o.columns,
        minimum
      ) .. "os últimos botões ficam cortados.",
    }
  end

  if in_window then
    if vim.o.laststatus ~= 3 then
      out[#out + 1] = {
        level = "warn",
        message = ("'laststatus' está %d: com statusline por janela, a barra ganha uma linha "):format(
          vim.o.laststatus
        ) .. "separadora e passa a custar duas linhas. Use vim.o.laststatus = 3.",
      }
    end
  elseif not vim.o.tabline:find "nvim%-toolbar" then
    out[#out + 1] = {
      level = "warn",
      message = "a tabline atual não é do nvim-toolbar: outro plugin (heirline, bufferline) a tomou. "
        .. "Chame require('nvim-toolbar').setup() depois dele.",
    }
  end

  if not vim.o.mousemoveevent then
    out[#out + 1] = {
      level = "info",
      message = "'mousemoveevent' desligado: o destaque do botão sob o mouse fica indisponível.",
    }
  end

  return out
end

function M.check()
  vim.health.start "nvim-toolbar"

  local problems = M.report()
  if #problems == 0 then
    vim.health.ok(("toolbar no ar (%s), mouse habilitado"):format(config.options.position))
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
