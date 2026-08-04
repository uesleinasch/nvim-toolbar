-- Sandbox de validação: não lê a sua config.
--   nvim -u demo/init.lua demo/exemplo.txt
vim.opt.rtp:append(vim.fn.fnamemodify(vim.fn.expand "<sfile>:p", ":h:h"))

vim.o.mouse = "a"
vim.o.number = true
vim.o.termguicolors = true
vim.o.swapfile = false

require("nvim-toolbar").setup()

vim.api.nvim_echo({
  { "nvim-toolbar", "Title" },
  { " — clique nos grupos da barra de cima. :checkhealth nvim-toolbar para diagnóstico." },
}, false, {})
