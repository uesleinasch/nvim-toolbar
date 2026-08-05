local model = require "nvim-toolbar.model"

local M = {}

-- Item sem `modes` e um comando de modo Normal: vale tambem no visual (o fluxo
-- de selecao depende disso), mas nunca em Insert/Replace/Select/Terminal —
-- senao as teclas viram texto digitado.
local TYPING_MODES = { i = true, R = true, t = true, s = true, S = true, ["\19"] = true }

local function allows(resolved, mode)
  if resolved.modes then return vim.tbl_contains(resolved.modes, mode) end
  return not TYPING_MODES[mode:sub(1, 1)]
end

local function to_normal(mode)
  if mode:sub(1, 1) == "t" then return "<C-\\><C-n>" end
  return "<Esc>"
end

function M.plan(resolved, ctx)
  local mode = (ctx and ctx.mode) or vim.fn.mode(1)

  if resolved.cmd then return { cmd = resolved.cmd, pending = resolved.pending } end

  local prefix = ""
  if not allows(resolved, mode) then prefix = to_normal(mode) end
  if resolved.on_selection and not model.is_visual(mode) then prefix = prefix .. "gv" end

  return { keys = prefix .. resolved.keys, pending = resolved.pending }
end

function M.run(resolved, ctx)
  local plan = M.plan(resolved, ctx)

  if plan.cmd then
    local ok, err = pcall(vim.cmd, plan.cmd)
    if not ok then plan.error = tostring(err):match "E%d+[^\n]*" or tostring(err) end
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(plan.keys, true, false, true), "n", false)
  end

  return plan
end

return M
