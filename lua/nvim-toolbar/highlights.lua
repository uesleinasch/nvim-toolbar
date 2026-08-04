local M = {}

M.links = {
  ToolbarGroup = "TabLine",
  ToolbarGroupOpen = "TabLineSel",
  ToolbarGroupHover = "TabLineSel",
  ToolbarAction = "TabLine",
  ToolbarActionHover = "TabLineSel",
  ToolbarSep = "TabLineFill",
  ToolbarFill = "TabLineFill",
  ToolbarMenu = "NormalFloat",
  ToolbarMenuBorder = "FloatBorder",
  ToolbarMenuSel = "PmenuSel",
  ToolbarEcho = "ModeMsg",
}

function M.setup()
  for name, link in pairs(M.links) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

return M
