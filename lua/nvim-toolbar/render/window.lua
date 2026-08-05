local buttons = require "nvim-toolbar.render.buttons"

local M = {}

local HL = {
  group = "ToolbarGroup",
  group_open = "ToolbarGroupOpen",
  group_hover = "ToolbarGroupHover",
  action = "ToolbarAction",
  action_hover = "ToolbarActionHover",
  sep = "ToolbarSep",
}

local NS = vim.api.nvim_create_namespace "nvim-toolbar-window"

local win = nil
local buf = nil
local targets = {}
local regions = {}
local saved_winbar = nil
local augroup = nil

-- identifica pelo filetype, e nao por comparar com `win`: no WinNew da propria
-- barra a variavel `win` ainda nao foi atribuida
local function is_normal_win(candidate)
  local ok, config = pcall(vim.api.nvim_win_get_config, candidate)
  if not ok or config.relative ~= "" then return false end
  local candidate_buf = vim.api.nvim_win_get_buf(candidate)
  return vim.bo[candidate_buf].filetype ~= "nvimtoolbar"
end

-- 'winbar' e global-local e um valor local vazio cai de volta no global, o que
-- roubaria a unica linha da barra. A saida e zerar o global e levar o valor
-- para cada janela de codigo.
local function adopt_winbar()
  local global = vim.o.winbar
  if global == "" or saved_winbar then return end

  saved_winbar = global
  vim.o.winbar = ""
  for _, candidate in ipairs(vim.api.nvim_list_wins()) do
    if is_normal_win(candidate) then vim.wo[candidate].winbar = global end
  end

  augroup = vim.api.nvim_create_augroup("NvimToolbarWinbar", { clear = true })
  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinNew" }, {
    group = augroup,
    callback = function()
      if not saved_winbar then return end
      local candidate = vim.api.nvim_get_current_win()
      if not is_normal_win(candidate) then return end
      if vim.api.nvim_get_option_value("winbar", { win = candidate, scope = "local" }) == "" then
        vim.wo[candidate].winbar = saved_winbar
      end
    end,
  })
end

local function restore_winbar()
  if not saved_winbar then return end

  if augroup then
    pcall(vim.api.nvim_del_augroup_by_id, augroup)
    augroup = nil
  end

  for _, candidate in ipairs(vim.api.nvim_list_wins()) do
    if is_normal_win(candidate) then pcall(function() vim.wo[candidate].winbar = "" end) end
  end
  vim.o.winbar = saved_winbar
  saved_winbar = nil
end

local function make_buf()
  if buf and vim.api.nvim_buf_is_valid(buf) then return buf end

  buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].filetype = "nvimtoolbar"
  vim.api.nvim_buf_set_name(buf, "nvim-toolbar")
  return buf
end

local function leave_bar()
  if not win or vim.api.nvim_get_current_win() ~= win then return end
  for _, candidate in ipairs(vim.api.nvim_list_wins()) do
    if is_normal_win(candidate) then return vim.api.nvim_set_current_win(candidate) end
  end
end

-- Sem isto, o :q na ultima janela de codigo deixa viva so a barra e o Neovim
-- nao sai: o usuario precisa de um segundo :q. O check roda depois do quit
-- (schedule) para nao derrubar a barra quando o usuario cancela um :confirm q.
-- O quit disparado aqui aciona QuitPre de novo; sem o guard `quitting`, cada
-- quit agenda outro e a cadeia estoura em E169 abortando o quit do usuario.
local quitting = false

local function quit_bar_when_alone()
  if quitting then return end
  vim.schedule(function()
    if quitting then return end
    if not (win and vim.api.nvim_win_is_valid(win)) then return end
    for _, candidate in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win))) do
      if is_normal_win(candidate) then return end
    end

    quitting = true
    if #vim.api.nvim_list_wins() == 1 then
      pcall(vim.cmd, "confirm quit")
    else
      pcall(vim.api.nvim_win_close, win, true)
    end
    quitting = false
  end)
end

-- A barra nao e lugar de trabalhar: se o foco cair nela, devolve ao codigo.
-- VimEnter/UIEnter entram aqui porque a barra e a primeira janela do layout e o
-- Neovim foca nela ao terminar de iniciar, sem passar por WinEnter.
local function guard_focus()
  local group = vim.api.nvim_create_augroup("NvimToolbarFocus", { clear = true })
  vim.api.nvim_create_autocmd({ "WinEnter", "VimEnter", "UIEnter", "TabEnter" }, {
    group = group,
    callback = function() vim.schedule(leave_bar) end,
  })
  vim.api.nvim_create_autocmd("QuitPre", { group = group, callback = quit_bar_when_alone })
end

local function make_win()
  if win and vim.api.nvim_win_is_valid(win) then return win end

  adopt_winbar()
  win = vim.api.nvim_open_win(make_buf(), false, { split = "above", win = -1, height = 1 })

  local wo = vim.wo[win]
  wo.winfixheight = true
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.foldcolumn = "0"
  wo.cursorline = false
  wo.cursorcolumn = false
  wo.list = false
  wo.wrap = false
  wo.winbar = ""
  wo.statusline = ""
  -- o separador entre a barra e o codigo e inevitavel em split; pintado com a cor
  -- da barra, ele le como a borda inferior dela
  wo.winhighlight = "Normal:ToolbarFill,EndOfBuffer:ToolbarFill,WinSeparator:ToolbarSep"

  -- winfixbuf esta fora de proposito: com ele, um clique na barra faz o Neovim
  -- abrir uma segunda janela em vez de reusar esta. O guard de foco abaixo
  -- protege a barra sem esse efeito.
  wo.winfixbuf = false

  -- o height do open_win nem sempre e respeitado na criacao do split
  vim.api.nvim_win_set_height(win, 1)

  guard_focus()

  return win
end

-- a barra e uma so: quando o usuario troca de tabpage, ela migra junto em vez
-- de ficar orfa na aba anterior
local function ensure_tabpage()
  if not (win and vim.api.nvim_win_is_valid(win)) then return end
  if vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage() then return end
  vim.api.nvim_win_close(win, true)
  win = nil
end

function M.setup()
  make_win()
  M.render {}
  return win
end

function M.render(opts)
  opts = opts or {}
  ensure_tabpage()
  make_win()

  targets, regions = {}, {}

  local list = buttons.build(vim.api.nvim_win_get_width(win))
  local text_parts = {}
  local col, byte, id = 0, 0, 0
  local marks = {}

  for _, button in ipairs(list) do
    local width = vim.fn.strdisplaywidth(button.text)
    local bytes = #button.text

    if button.separator then
      marks[#marks + 1] = { byte, byte + bytes, HL.sep }
    else
      id = id + 1
      targets[id] = { kind = button.kind, id = button.id }
      regions[id] = { col = col, width = width }

      local hl
      if button.kind == "group" then
        hl = HL.group
        if opts.open == button.id then
          hl = HL.group_open
        elseif opts.hover == id then
          hl = HL.group_hover
        end
      else
        hl = opts.hover == id and HL.action_hover or HL.action
      end

      marks[#marks + 1] = { byte, byte + bytes, hl }
    end

    text_parts[#text_parts + 1] = button.text
    col = col + width
    byte = byte + bytes
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { table.concat(text_parts) })
  vim.bo[buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, NS, 0, mark[1], { end_col = mark[2], hl_group = mark[3] })
  end
end

function M.button_at(wincol)
  local col = wincol - 1
  for id, region in pairs(regions) do
    if col >= region.col and col < region.col + region.width then return id end
  end
  return nil
end

-- clique na tabline chega com winid da barra (primeira janela do layout) e
-- winrow = 0: sem exigir winrow 1, a aba clicada viraria botao da toolbar
function M.hit(pos)
  if not win or pos.winid ~= win then return nil end
  if pos.winrow ~= 1 then return nil end
  return M.button_at(pos.wincol)
end

function M.region(id) return regions[id] end

function M.target(id) return targets[id] end

function M.win() return win end

function M.teardown()
  pcall(vim.api.nvim_del_augroup_by_name, "NvimToolbarFocus")
  if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  if buf and vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
  win, buf, targets, regions = nil, nil, {}, {}
  restore_winbar()
end

return M
