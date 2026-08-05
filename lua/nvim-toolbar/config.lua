local M = {}

local defaults = {
  position = "tabline",
  echo = true,
  hover = true,
  groups = nil,
}

M.options = vim.deepcopy(defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  return M.options
end

function M.groups() return M.options.groups or require("nvim-toolbar.catalog").groups end

return M
