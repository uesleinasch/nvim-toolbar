local actions = require "nvim-toolbar.actions"
local catalog = require "nvim-toolbar.catalog"
local context = require "nvim-toolbar.context"
local model = require "nvim-toolbar.model"

local M = {}

local state = { win = nil, buf = nil, entries = {}, anchor = nil, open_group = nil }

local function group_by_id(id)
  for _, group in ipairs(catalog.groups) do
    if group.id == id then return group end
  end
end

local function action_by_id(id)
  for _, action in ipairs(catalog.actions) do
    if action.id == id then return action end
  end
end

local function entries_of(items)
  local entries = {}
  for _, item in ipairs(items) do
    if item.separator then
      entries[#entries + 1] = { separator = true }
    else
      local text = model.label(item)
      if item.targets then text = text .. "  ▸" end
      entries[#entries + 1] = { item = item, text = text }
    end
  end
  return entries
end

local function target_entries(resolved)
  local entries = {}
  for _, target in ipairs(resolved.items) do
    entries[#entries + 1] = { item = target, text = model.label(target) }
  end
  return entries
end

local function keymaps(buf)
  local function map(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true }) end

  map("<CR>", function() M.choose(vim.fn.line ".") end)
  map("<Esc>", function() M.close() end)
  map("q", function() M.close() end)

  -- Pressionar, nao soltar: o release do clique que abre o menu chega quando o menu
  -- ja tem foco e escolheria o primeiro item sozinho.
  map("<LeftMouse>", function()
    local pos = vim.fn.getmousepos()
    if pos.winid == state.win and pos.line > 0 then return M.choose(pos.line) end
    M.close()
  end)
end

local function draw(entries, anchor)
  local width = 0
  for _, entry in ipairs(entries) do
    if entry.text then width = math.max(width, vim.fn.strdisplaywidth(entry.text)) end
  end
  width = width + 2

  local lines = {}
  for _, entry in ipairs(entries) do
    lines[#lines + 1] = entry.separator and ("─"):rep(width) or (" " .. entry.text)
  end

  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    keymaps(buf)
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local col = math.max(0, math.min(anchor.col, vim.o.columns - width - 2))
  local win_config = {
    relative = "editor",
    row = anchor.row or 1,
    col = col,
    width = width,
    height = math.min(#lines, vim.o.lines - 4),
    style = "minimal",
    border = "rounded",
  }

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_set_config(state.win, win_config)
  else
    state.win = vim.api.nvim_open_win(buf, true, win_config)
    vim.wo[state.win].winhighlight = "Normal:ToolbarMenu,FloatBorder:ToolbarMenuBorder,CursorLine:ToolbarMenuSel"
    vim.wo[state.win].cursorline = true
  end

  state.buf = buf
  state.entries = entries
  state.anchor = anchor
end

function M.open(target, anchor)
  context.capture()

  if target.kind == "action" then return M.invoke_action(target.id) end

  local group = group_by_id(target.id)
  if not group then return end

  state.open_group = group.id
  draw(entries_of(group.items), anchor or { col = 0 })
  if M.on_change then M.on_change() end
end

function M.choose(line)
  local entry = state.entries[line]
  if not entry or entry.separator then return end

  local resolved = actions.invoke(entry.item)

  if resolved.kind == "targets" then
    draw(target_entries(resolved), state.anchor)
    return resolved
  end

  M.close()
  return resolved
end

function M.invoke_action(id)
  local action = action_by_id(id)
  if not action then return end

  context.capture()
  local resolved = actions.invoke(action)
  M.close()
  return resolved
end

function M.items()
  local items = {}
  for i, entry in ipairs(state.entries) do
    items[i] = entry.separator and { separator = true } or entry.item
  end
  return items
end

function M.is_open() return state.win ~= nil and vim.api.nvim_win_is_valid(state.win) end

function M.win() return state.win end

function M.open_group() return M.is_open() and state.open_group or nil end

function M.close()
  local was_open = state.win ~= nil
  if state.win and vim.api.nvim_win_is_valid(state.win) then vim.api.nvim_win_close(state.win, true) end
  state.win, state.buf, state.entries, state.anchor, state.open_group = nil, nil, {}, nil, nil

  if not was_open then return end

  context.restore()
  if M.on_change then M.on_change() end
end

return M
