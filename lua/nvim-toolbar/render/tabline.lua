local buttons = require "nvim-toolbar.render.buttons"

local M = {}

local HL = {
  group = "ToolbarGroup",
  group_open = "ToolbarGroupOpen",
  group_hover = "ToolbarGroupHover",
  action = "ToolbarAction",
  action_hover = "ToolbarActionHover",
  sep = "ToolbarSep",
  fill = "ToolbarFill",
}

local targets = {}
local regions = {}
local width = 0
local current_opts = {}
local saved_tabline = nil
local saved_showtabline = nil

function M.setup()
  saved_tabline = vim.o.tabline
  saved_showtabline = vim.o.showtabline
  vim.o.tabline = "%!v:lua.require'nvim-toolbar'.render()"
  vim.o.showtabline = 2
end

function M.render(opts)
  current_opts = opts or {}
  pcall(vim.cmd, "redrawtabline")
end

function M.teardown()
  if saved_tabline ~= nil then vim.o.tabline = saved_tabline end
  if saved_showtabline ~= nil then vim.o.showtabline = saved_showtabline end
  saved_tabline, saved_showtabline, current_opts = nil, nil, {}
end

function M.build(opts)
  opts = opts or current_opts or {}
  targets, regions = {}, {}

  local list = buttons.build(vim.o.columns)
  width = buttons.width(list)

  local out = {}
  local col = 0
  local id = 0

  for _, button in ipairs(list) do
    if button.separator then
      out[#out + 1] = ("%%#%s#%s"):format(HL.sep, button.text)
    else
      id = id + 1
      targets[id] = { kind = button.kind, id = button.id }
      regions[id] = { col = col, width = vim.fn.strdisplaywidth(button.text) }

      local hl
      if button.kind == "group" then
        hl = HL.group
        if opts.open == button.id then
          hl = HL.group_open
        elseif opts.hover == id then
          hl = HL.group_hover
        end
      else
        hl = opts.hover == id and HL.action_hover or HL.action
      end

      out[#out + 1] = ("%%#%s#%%%d@v:lua.NvimToolbarClick@%s%%X"):format(hl, id, button.text)
    end
    col = col + vim.fn.strdisplaywidth(button.text)
  end

  out[#out + 1] = "%#" .. HL.fill .. "#%="

  return table.concat(out)
end

function M.target(id) return targets[id] end

function M.region(id) return regions[id] end

function M.width() return width end

function M.button_at(screencol)
  local col = screencol - 1
  local id = 1
  while true do
    local region = regions[id]
    if not region then return nil end
    if col >= region.col and col < region.col + region.width then return id end
    id = id + 1
  end
end

function M.hit(pos)
  if pos.screenrow ~= 1 then return nil end
  return M.button_at(pos.screencol)
end

return M
