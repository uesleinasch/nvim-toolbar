local config = require "nvim-toolbar.config"
local highlights = require "nvim-toolbar.highlights"
local hover = require "nvim-toolbar.hover"
local menu = require "nvim-toolbar.menu"
local tabline = require "nvim-toolbar.render.tabline"

local M = {}

local saved_tabline = nil
local enabled = false

function _G.NvimToolbarClick(id)
  local target = tabline.target(id)
  if not target then return end

  if target.kind == "action" then
    menu.close()
    return menu.invoke_action(target.id)
  end

  if menu.is_open() and menu.open_group() == target.id then return menu.close() end

  menu.close()
  local region = tabline.region(id) or { col = 0 }
  return menu.open(target, { col = region.col, row = 1 })
end

function M.render() return tabline.build { open = menu.open_group(), hover = hover.current() } end

function M.enable()
  if enabled then return end

  saved_tabline = vim.o.tabline
  highlights.setup()
  vim.o.tabline = "%!v:lua.require'nvim-toolbar'.render()"
  vim.o.showtabline = 2
  enabled = true
end

function M.disable()
  if not enabled then return end

  menu.close()
  vim.o.tabline = saved_tabline or ""
  enabled = false
end

function M.toggle()
  if enabled then M.disable() else M.enable() end
end

function M.is_enabled() return enabled end

function M.setup(opts)
  config.setup(opts)

  local function redraw()
    if enabled then pcall(vim.cmd, "redrawtabline") end
  end

  menu.on_change = redraw
  hover.on_change = redraw
  hover.setup()

  vim.api.nvim_create_user_command("ToolbarToggle", M.toggle, { desc = "Liga ou desliga a toolbar" })
  vim.api.nvim_create_user_command("ToolbarEnable", M.enable, { desc = "Liga a toolbar" })
  vim.api.nvim_create_user_command("ToolbarDisable", M.disable, { desc = "Desliga a toolbar" })

  M.enable()

  return M
end

return M
