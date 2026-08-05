local root = vim.fn.fnamemodify(vim.fn.expand "<sfile>:p", ":h:h")

local plenary = os.getenv "PLENARY_DIR" or vim.fn.expand "~/.local/share/nvim/lazy/plenary.nvim"
if vim.fn.isdirectory(plenary) == 0 then
  plenary = root .. "/.tests/plenary.nvim"
  if vim.fn.isdirectory(plenary) == 0 then
    vim.fn.system { "git", "clone", "--depth=1", "https://github.com/nvim-lua/plenary.nvim", plenary }
  end
end

vim.opt.rtp:append(root)
vim.opt.rtp:append(plenary)

vim.opt.swapfile = false
vim.cmd "runtime plugin/plenary.vim"
