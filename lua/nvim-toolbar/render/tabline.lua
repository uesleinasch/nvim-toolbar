local catalog = require "nvim-toolbar.catalog"
local model = require "nvim-toolbar.model"

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

local SEP = " │ "

local targets = {}
local regions = {}
local width = 0

local function buttons_of(compact)
  local buttons = {}

  for _, group in ipairs(catalog.groups) do
    local text = compact and (" " .. group.label .. " ") or (" " .. group.label .. " ▾")
    buttons[#buttons + 1] = { kind = "group", id = group.id, text = text }
  end

  buttons[#buttons + 1] = { separator = true, text = SEP }

  for _, action in ipairs(catalog.actions) do
    local shortcut = model.display_keys(action)
    local text = action.icon and (action.icon .. " " .. shortcut) or shortcut
    if compact then text = action.icon or shortcut end
    buttons[#buttons + 1] = { kind = "action", id = action.id, text = " " .. text .. " " }
  end

  return buttons
end

local function measure(buttons)
  local total = 0
  for _, button in ipairs(buttons) do
    total = total + vim.fn.strdisplaywidth(button.text)
  end
  return total
end

function M.build(opts)
  opts = opts or {}
  targets, regions = {}, {}

  local buttons = buttons_of(false)
  if measure(buttons) > vim.o.columns then buttons = buttons_of(true) end
  width = measure(buttons)

  local out = {}
  local col = 0
  local id = 0

  for _, button in ipairs(buttons) do
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

return M
