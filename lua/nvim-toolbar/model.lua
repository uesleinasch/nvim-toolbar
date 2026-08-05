local catalog = require "nvim-toolbar.catalog"

local M = {}

function M.is_visual(mode)
  local first = (mode or ""):sub(1, 1)
  return first == "v" or first == "V" or first == "\22"
end

local function compose(keys, target)
  if target.template then return target.template:format(keys) end
  if target.form == "line" then return keys .. keys:sub(-1) end
  return keys .. target.suffix
end

function M.display_keys(item)
  if item.display then return item.display end
  if item.cmd then return ":" .. item.cmd end
  return (item.keys:gsub("<[cC]%-(.)>", function(key) return "^" .. key:lower() end))
end

function M.label(item)
  local shortcut = M.display_keys(item)
  if item.alias then shortcut = shortcut .. " / " .. item.alias end
  return shortcut .. " - " .. item.label
end

function M.resolve(item, mode)
  local visual = M.is_visual(mode)

  if item.targets and not visual then
    local set = catalog.targets[item.targets]
    local items = {}
    for _, target in ipairs(set) do
      items[#items + 1] = { keys = compose(item.keys, target), label = target.label, parent = item }
    end
    return { kind = "targets", item = item, items = items }
  end

  return {
    kind = "action",
    cmd = item.cmd,
    keys = item.keys,
    label = item.label,
    pending = item.pending,
    modes = item.modes,
    on_selection = visual or nil,
  }
end

return M
