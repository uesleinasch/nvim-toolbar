-- Harness de mouse real: nvim dentro do tmux, cliques como sequencias SGR.
-- Usado porque nvim_input_mouse exige UI atachada e um nvim nao sustenta ser UI de outro.
local M = {}

local TMP = "/tmp/nvim-toolbar-mouse"

function M.available() return vim.fn.executable "tmux" == 1 end

local function sh(cmd) return vim.fn.system(cmd) end

local function hex_of(str)
  local bytes = {}
  for i = 1, #str do
    bytes[#bytes + 1] = ("%02x"):format(str:byte(i))
  end
  return table.concat(bytes, " ")
end

function M.setup_files(lines)
  vim.fn.mkdir(TMP, "p")
  local root = vim.fn.getcwd()

  local init = ([[
vim.opt.rtp:append(%q)
vim.o.mouse = "a"
vim.o.swapfile = false
vim.o.laststatus = 0

local toolbar = require "nvim-toolbar"
local menu = require "nvim-toolbar.menu"
local tabline = require "nvim-toolbar.render.tabline"

toolbar.setup { echo = false, hover = false }

vim.api.nvim_buf_set_lines(0, 0, -1, false, %s)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd "let &l:undolevels = &l:undolevels"

local function dump(path, data) vim.fn.writefile({ vim.json.encode(data) }, path) end

local function regions()
  tabline.build()
  local out = {}
  for id = 1, 40 do
    local target = tabline.target(id)
    if not target then break end
    local region = tabline.region(id)
    out[#out + 1] = { id = id, kind = target.kind, name = target.id, col = region.col, width = region.width }
  end
  return out
end

local function snapshot()
  local data = {
    menu_open = menu.is_open(),
    group = menu.open_group(),
    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false),
    register = vim.fn.getreg '"',
    mode = vim.fn.mode(1),
    captured_mode = require("nvim-toolbar.context").state().mode,
  }

  local target_win = require("nvim-toolbar.context").state().win
  if target_win and vim.api.nvim_win_is_valid(target_win) then
    data.marks = vim.api.nvim_win_call(target_win, function()
      return { lt = vim.fn.getpos "'<", gt = vim.fn.getpos "'>" }
    end)
  end
  if menu.is_open() then
    local win = menu.win()
    local cfg = vim.api.nvim_win_get_config(win)
    data.menu = {
      row = cfg.row,
      col = cfg.col,
      width = cfg.width,
      lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false),
    }
  end
  return data
end

local step = 0
menu.on_change = function()
  step = step + 1
  local current = step
  -- espera o typeahead do feedkeys ser processado antes de fotografar o buffer
  vim.defer_fn(function()
    dump("%s/step" .. current .. ".json", snapshot())
    vim.fn.system { "tmux", "wait-for", "-S", "toolbar-step" .. current }
  end, 250)
end

-- avisa quando a selecao visual chegou na linha pedida, para o teste nao
-- clicar antes de o typeahead ser processado
local visual_done = false
vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" }, {
  callback = function()
    local mode = vim.fn.mode(1)
    local visual = mode == "v" or mode == "V" or mode == "\22"
    if not visual_done and visual and vim.fn.line "." == vim.g.toolbar_wait_line then
      visual_done = true
      vim.fn.system { "tmux", "wait-for", "-S", "toolbar-visual" }
    end
  end,
})

dump("%s/regions.json", regions())
vim.fn.system { "tmux", "wait-for", "-S", "toolbar-ready" }
]]):format(root, vim.inspect(lines), TMP, TMP, TMP)

  vim.fn.writefile(vim.split(init, "\n"), TMP .. "/init.lua")
  vim.fn.delete(TMP .. "/regions.json")
  for i = 1, 6 do
    vim.fn.delete(TMP .. "/step" .. i .. ".json")
  end
  return TMP
end

function M.start(session, lines)
  local dir = M.setup_files(lines)
  sh { "tmux", "kill-session", "-t", session }
  sh(("tmux new-session -d -s %s -x 100 -y 24 'nvim --clean -u %s/init.lua'"):format(session, dir))
  return dir
end

function M.wait(signal, seconds)
  sh(("timeout %d tmux wait-for %s"):format(seconds or 15, signal))
end

function M.click(session, screenrow, screencol)
  local press = ("\27[<0;%d;%dM"):format(screencol, screenrow)
  local release = ("\27[<0;%d;%dm"):format(screencol, screenrow)
  sh(("tmux send-keys -t %s -H %s"):format(session, hex_of(press)))
  sh(("tmux send-keys -t %s -H %s"):format(session, hex_of(release)))
end

function M.type(session, keys) sh { "tmux", "send-keys", "-t", session, keys } end

-- seleciona linhas com o teclado e so retorna quando o Neovim confirma o estado
function M.select_lines(session, count)
  M.type(session, (":let g:toolbar_wait_line = %d\r"):format(count))
  M.type(session, "gg" .. (count > 1 and ("V" .. ("j"):rep(count - 1)) or "V"))
  M.wait "toolbar-visual"
end

function M.read(path)
  vim.wait(5000, function() return vim.uv.fs_stat(path) ~= nil end, 50)
  local content = vim.fn.readfile(path)
  if #content == 0 then return nil end
  return vim.json.decode(content[1])
end

function M.capture(session) return sh { "tmux", "capture-pane", "-t", session, "-p" } end

function M.stop(session) sh { "tmux", "kill-session", "-t", session } end

function M.region(regions, name)
  for _, region in ipairs(regions) do
    if region.name == name then return region end
  end
end

return M
