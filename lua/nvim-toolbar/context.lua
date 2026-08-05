local M = {}

local state = { win = nil, mode = "n" }

-- alvo valido e a janela onde o usuario edita: nem flutuante (menu) nem a barra
local function is_target(win)
  local ok, config = pcall(vim.api.nvim_win_get_config, win)
  if not ok or config.relative ~= "" then return false end
  return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "nvimtoolbar"
end

function M.reset() state = { win = nil, mode = "n" } end

function M.state() return state end

function M.capture()
  local win = vim.api.nvim_get_current_win()
  if is_target(win) then
    state.win = win
    state.mode = vim.fn.mode(1)
  end
  return state
end

function M.restore()
  if state.win and vim.api.nvim_win_is_valid(state.win) then vim.api.nvim_set_current_win(state.win) end
end

return M
