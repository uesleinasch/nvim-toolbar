local model = require "nvim-toolbar.model"

local M = {}

local function allows(resolved, mode)
  if not resolved.modes then return true end
  return vim.tbl_contains(resolved.modes, mode)
end

function M.plan(resolved, ctx)
  local mode = (ctx and ctx.mode) or vim.fn.mode(1)

  if resolved.cmd then return { cmd = resolved.cmd, pending = resolved.pending } end

  local prefix = ""
  if not allows(resolved, mode) then prefix = "<Esc>" end
  if resolved.on_selection and not model.is_visual(mode) then prefix = prefix .. "gv" end

  return { keys = prefix .. resolved.keys, pending = resolved.pending }
end

function M.run(resolved, ctx)
  local plan = M.plan(resolved, ctx)

  if plan.cmd then
    vim.cmd(plan.cmd)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(plan.keys, true, false, true), "n", false)
  end

  return plan
end

return M
