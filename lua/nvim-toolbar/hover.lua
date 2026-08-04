local config = require "nvim-toolbar.config"
local tabline = require "nvim-toolbar.render.tabline"

local M = {}

local current = nil

function M.reset() current = nil end

function M.current() return current end

function M.button_at(screencol)
  local col = screencol - 1
  local id = 1
  while true do
    local region = tabline.region(id)
    if not region then return nil end
    if col >= region.col and col < region.col + region.width then return id end
    id = id + 1
  end
end

function M.handle(pos)
  local id = pos.screenrow == 1 and M.button_at(pos.screencol) or nil

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
    M.handle(vim.fn.getmousepos())
    return ""
  end, { expr = true, silent = true, desc = "nvim-toolbar: destaque sob o mouse" })
end

return M
