local config = require "nvim-toolbar.config"
local highlights = require "nvim-toolbar.highlights"
local hover = require "nvim-toolbar.hover"
local menu = require "nvim-toolbar.menu"
local render = require "nvim-toolbar.render"
local tabline = require "nvim-toolbar.render.tabline"

local M = {}

local enabled = false

local function state_opts() return { open = menu.open_group(), hover = hover.current() } end

local function activate(id)
  local target = render.target(id)
  if not target then return end

  if target.kind == "action" then
    menu.close()
    return menu.invoke_action(target.id)
  end

  if menu.is_open() and menu.open_group() == target.id then return menu.close() end

  menu.close()
  local region = render.region(id) or { col = 0 }
  local row = render.name() == "window" and 2 or 1
  return menu.open(target, { col = region.col, row = row })
end

function _G.NvimToolbarClick(id) return activate(id) end

-- O renderer de janela precisa de mappings globais: um buffer-local nao dispara no
-- primeiro clique, porque nesse instante o buffer atual ainda e o do codigo.
local MOUSE_MODES = { "n", "v", "i" }
local MOUSE_KEYS = { "<LeftMouse>", "<LeftRelease>", "<LeftDrag>", "<2-LeftMouse>", "<3-LeftMouse>" }

local mouse_installed = false
local saved_mouse_maps = {}

local function install_mouse()
  saved_mouse_maps = {}
  for _, key in ipairs(MOUSE_KEYS) do
    for _, mode in ipairs(MOUSE_MODES) do
      local existing = vim.fn.maparg(key, mode, false, true)
      if existing.lhs then saved_mouse_maps[#saved_mouse_maps + 1] = existing end
    end

    -- so o press age; os demais existem para que o comportamento nativo nao leve
    -- o foco para a barra depois de o press ja ter sido tratado
    local acts = key == "<LeftMouse>"
    vim.keymap.set(MOUSE_MODES, key, function()
      local id = render.hit(vim.fn.getmousepos())
      if not id then return key end
      if acts then vim.schedule(function() activate(id) end) end
      return "<Ignore>"
    end, { expr = true, replace_keycodes = true, silent = true, desc = "nvim-toolbar: clique na barra" })
  end
  mouse_installed = true
end

local function uninstall_mouse()
  if not mouse_installed then return end

  for _, key in ipairs(MOUSE_KEYS) do
    pcall(vim.keymap.del, MOUSE_MODES, key)
  end
  for _, mapping in ipairs(saved_mouse_maps) do
    pcall(vim.fn.mapset, mapping)
  end
  saved_mouse_maps = {}
  mouse_installed = false
end

function M.render() return tabline.build(state_opts()) end

function M.refresh()
  if enabled then render.render(state_opts()) end
end

function M.enable()
  if enabled then return end

  highlights.setup()
  render.setup()
  hover.setup()
  if render.name() == "window" then install_mouse() end

  local group = vim.api.nvim_create_augroup("NvimToolbar", { clear = true })
  vim.api.nvim_create_autocmd({ "VimResized", "TabEnter", "WinNew", "WinClosed" }, {
    group = group,
    callback = function() vim.schedule(M.refresh) end,
  })

  enabled = true
  M.refresh()
end

function M.disable()
  if not enabled then return end

  menu.close()
  hover.teardown()
  uninstall_mouse()
  pcall(vim.api.nvim_del_augroup_by_name, "NvimToolbar")
  render.teardown()
  enabled = false
end

function M.toggle()
  if enabled then M.disable() else M.enable() end
end

function M.is_enabled() return enabled end

function M.setup(opts)
  if vim.fn.has "nvim-0.10" == 0 then
    vim.notify("nvim-toolbar requer Neovim 0.10 ou mais novo", vim.log.levels.ERROR)
    return M
  end

  config.setup(opts)

  menu.on_change = M.refresh
  hover.on_change = M.refresh

  vim.api.nvim_create_user_command("ToolbarToggle", M.toggle, { desc = "Liga ou desliga a toolbar" })
  vim.api.nvim_create_user_command("ToolbarEnable", M.enable, { desc = "Liga a toolbar" })
  vim.api.nvim_create_user_command("ToolbarDisable", M.disable, { desc = "Desliga a toolbar" })

  -- setup de novo (reload de config) reconfigura de verdade em vez de ignorar
  if enabled then M.disable() end
  M.enable()

  return M
end

return M
