local config = require "nvim-toolbar.config"

local M = {}

local MODULES = {
  tabline = "nvim-toolbar.render.tabline",
  window = "nvim-toolbar.render.window",
}

local active = nil
local active_name = nil

function M.name() return active_name end

function M.current() return active end

function M.setup()
  local wanted = config.options.position
  active_name = MODULES[wanted] and wanted or "tabline"
  active = require(MODULES[active_name])
  active.setup()
  return active
end

function M.render(opts)
  if active then active.render(opts) end
end

function M.hit(pos)
  if not active then return nil end
  return active.hit(pos)
end

function M.target(id)
  if not active then return nil end
  return active.target(id)
end

function M.region(id)
  if not active then return nil end
  return active.region(id)
end

function M.teardown()
  if active then active.teardown() end
  active, active_name = nil, nil
end

return M
