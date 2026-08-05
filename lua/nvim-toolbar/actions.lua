local config = require "nvim-toolbar.config"
local context = require "nvim-toolbar.context"
local echo = require "nvim-toolbar.echo"
local exec = require "nvim-toolbar.exec"
local model = require "nvim-toolbar.model"

local M = {}

function M.invoke(item)
  local resolved = model.resolve(item, context.state().mode)
  if resolved.kind == "targets" then return resolved end

  context.restore()
  local plan = exec.run(resolved)

  if plan.error then
    resolved.error = plan.error
    vim.api.nvim_echo({ { plan.error, "ErrorMsg" } }, true, {})
    return resolved
  end

  resolved.echo = echo.message(item)
  if config.options.echo then vim.api.nvim_echo({ { resolved.echo, "ToolbarEcho" } }, false, {}) end

  return resolved
end

return M
