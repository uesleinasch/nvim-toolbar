local plenary = os.getenv("PLENARY_DIR") or vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim")
local root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:p"), ":h:h")

vim.opt.rtp:append(root)
vim.opt.rtp:append(plenary)

vim.opt.swapfile = false
vim.cmd("runtime plugin/plenary.vim")
