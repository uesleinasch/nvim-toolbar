local config = require "nvim-toolbar.config"
local render = require "nvim-toolbar.render"

local M = {}

local current = nil

function M.reset() current = nil end

function M.current() return current end

function M.handle(pos)
  local id = render.hit(pos)

  if id ~= current then
    current = id
    if M.on_change then M.on_change() end
  end

  return current
end

function M.setup()
  if not config.options.hover then return end

  vim.o.mousemoveevent = true
  vim.keymap.set({ "n", "v", "i" }, "<MouseMove>", function()
    local pos = vim.fn.getmousepos()
    -- expr mapping proibe alterar texto ou janela (E565), e o renderer de janela
    -- redesenha escrevendo num buffer: o redesenho vai para o proximo tick
    vim.schedule(function() M.handle(pos) end)
    return ""
  end, { expr = true, silent = true, desc = "nvim-toolbar: destaque sob o mouse" })
end

return M
