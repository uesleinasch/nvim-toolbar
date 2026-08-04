local M = {}

local state = { win = nil, mode = "n" }

local function is_float(win)
  local ok, config = pcall(vim.api.nvim_win_get_config, win)
  return ok and config.relative ~= ""
end

function M.reset() state = { win = nil, mode = "n" } end

function M.state() return state end

function M.capture()
  local win = vim.api.nvim_get_current_win()
  if not is_float(win) then state.win = win end
  state.mode = vim.fn.mode(1)
  return state
end

function M.restore()
  if state.win and vim.api.nvim_win_is_valid(state.win) then vim.api.nvim_set_current_win(state.win) end
end

return M
