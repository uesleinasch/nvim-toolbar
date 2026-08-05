local config = require "nvim-toolbar.config"
local render = require "nvim-toolbar.render"

local M = {}

local MODES = { "n", "v", "i" }

local current = nil
local installed = false
local saved_mousemoveevent = nil
local saved_maps = {}

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
  if installed or not config.options.hover then return end

  saved_mousemoveevent = vim.o.mousemoveevent
  saved_maps = {}
  for _, mode in ipairs(MODES) do
    local existing = vim.fn.maparg("<MouseMove>", mode, false, true)
    if existing.lhs then saved_maps[#saved_maps + 1] = existing end
  end

  vim.o.mousemoveevent = true
  vim.keymap.set(MODES, "<MouseMove>", function()
    local pos = vim.fn.getmousepos()
    -- expr mapping proibe alterar texto ou janela (E565), e o renderer de janela
    -- redesenha escrevendo num buffer: o redesenho vai para o proximo tick
    vim.schedule(function() M.handle(pos) end)
    return ""
  end, { expr = true, silent = true, desc = "nvim-toolbar: destaque sob o mouse" })

  installed = true
end

function M.teardown()
  if not installed then return end

  pcall(vim.keymap.del, MODES, "<MouseMove>")
  for _, mapping in ipairs(saved_maps) do
    pcall(vim.fn.mapset, mapping)
  end
  saved_maps = {}
  vim.o.mousemoveevent = saved_mousemoveevent
  installed = false
  M.reset()
end

return M
