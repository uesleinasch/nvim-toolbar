local model = require "nvim-toolbar.model"

local M = {}

function M.message(item)
  local shortcut = model.display_keys(item)

  if item.pending then return shortcut .. " → complete o comando e pressione Enter" end

  local what = item.parent and (item.parent.label .. " · " .. item.label) or item.label
  return shortcut .. " → " .. what
end

return M
