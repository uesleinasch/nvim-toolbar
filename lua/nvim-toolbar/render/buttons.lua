local catalog = require "nvim-toolbar.catalog"
local model = require "nvim-toolbar.model"

local M = {}

M.separator_text = " │ "

local function compose(compact)
  local list = {}

  for _, group in ipairs(catalog.groups) do
    local text = compact and (" " .. group.label .. " ") or (" " .. group.label .. " ▾")
    list[#list + 1] = { kind = "group", id = group.id, text = text }
  end

  list[#list + 1] = { separator = true, text = M.separator_text }

  for _, action in ipairs(catalog.actions) do
    local shortcut = model.display_keys(action)
    local text = action.icon and (action.icon .. " " .. shortcut) or shortcut
    if compact then text = action.icon or shortcut end
    list[#list + 1] = { kind = "action", id = action.id, text = " " .. text .. " " }
  end

  return list
end

function M.width(list)
  local total = 0
  for _, button in ipairs(list) do
    total = total + vim.fn.strdisplaywidth(button.text)
  end
  return total
end

function M.build(available)
  local list = compose(false)
  if M.width(list) > (available or vim.o.columns) then list = compose(true) end
  return list
end

function M.minimum_width() return M.width(compose(true)) end

return M
