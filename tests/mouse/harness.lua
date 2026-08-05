-- Harness de mouse real: nvim dentro do tmux, cliques como sequencias SGR.
-- Usado porque nvim_input_mouse exige UI atachada e um nvim nao sustenta ser UI de
-- outro (o canal RPC morre no nvim_ui_attach), e nvim -l nao roda o loop de input.
--
-- Cada sessao tem diretorio e sinais proprios: os arquivos de spec rodam em
-- processos separados e colidiriam usando nomes fixos.
local M = {}

local BASE = "/tmp/nvim-toolbar-mouse"

function M.available() return vim.fn.executable "tmux" == 1 end

local function sh(cmd) return vim.fn.system(cmd) end

local function hex_of(str)
  local bytes = {}
  for i = 1, #str do
    bytes[#bytes + 1] = ("%02x"):format(str:byte(i))
  end
  return table.concat(bytes, " ")
end

local function dir_of(session) return BASE .. "/" .. session end

function M.setup_files(session, lines, opts)
  local dir = dir_of(session)
  vim.fn.delete(dir, "rf")
  -- os arquivos de spec rodam em paralelo e correm para criar o BASE
  -- compartilhado: o mkdir("p") perdedor estoura E739
  pcall(vim.fn.mkdir, dir, "p")
  if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end

  local root = vim.fn.getcwd()
  opts = vim.tbl_extend("force", { echo = false, hover = false }, opts or {})
  local showtabline = opts.showtabline or 1
  opts.showtabline = nil

  local init = ([[
vim.opt.rtp:append(%q)
vim.o.mouse = "a"
vim.o.swapfile = false
vim.o.showtabline = %d
-- 3 como no AstroNvim: com statusline por janela, a barra ganharia uma
-- statusline separadora e custaria uma linha extra
vim.o.laststatus = 3

local toolbar = require "nvim-toolbar"
local menu = require "nvim-toolbar.menu"
local render = require "nvim-toolbar.render"
local context = require "nvim-toolbar.context"

local DIR = %q
local SESSION = %q

toolbar.setup(%s)

vim.api.nvim_buf_set_lines(0, 0, -1, false, %s)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd "let &l:undolevels = &l:undolevels"

local function dump(name, data) vim.fn.writefile({ vim.json.encode(data) }, DIR .. "/" .. name .. ".json") end
local function signal(name) vim.fn.system { "tmux", "wait-for", "-S", name .. "-" .. SESSION } end

local function regions()
  if render.name() == "tabline" then toolbar.render() end
  local out = {}
  for id = 1, 40 do
    local target = render.target(id)
    if not target then break end
    local region = render.region(id)
    out[#out + 1] = { id = id, kind = target.kind, name = target.id, col = region.col, width = region.width }
  end
  return out
end

local function snapshot()
  local code_win = context.state().win
  local code_buf = code_win and vim.api.nvim_win_is_valid(code_win) and vim.api.nvim_win_get_buf(code_win) or 0
  local data = {
    menu_open = menu.is_open(),
    group = menu.open_group(),
    lines = vim.api.nvim_buf_get_lines(code_buf, 0, -1, false),
    register = vim.fn.getreg '"',
    mode = vim.fn.mode(1),
    captured_mode = context.state().mode,
    focus_filetype = vim.bo.filetype,
    renderer = render.name(),
  }
  if menu.is_open() then
    local cfg = vim.api.nvim_win_get_config(menu.win())
    data.menu = {
      row = cfg.row,
      col = cfg.col,
      width = cfg.width,
      lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(menu.win()), 0, -1, false),
    }
  end
  return data
end

local visual_done = false
vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" }, {
  callback = function()
    local mode = vim.fn.mode(1)
    local visual = mode == "v" or mode == "V" or mode == "\22"
    if not visual_done and visual and vim.fn.line "." == vim.g.toolbar_wait_line then
      visual_done = true
      signal "visual"
    end
  end,
})

local step = 0
menu.on_change = function()
  step = step + 1
  local current = step
  -- espera o typeahead do feedkeys ser processado antes de fotografar o buffer
  vim.defer_fn(function()
    dump("step" .. current, snapshot())
    signal("step" .. current)
  end, 250)
end

-- o Neovim pode focar a barra ao terminar de iniciar; so avisa "ready" quando o
-- foco ja estabilizou no codigo, senao as teclas do teste vao para a barra
vim.defer_fn(function()
  dump("regions", regions())
  dump("ready", { foco_ft = vim.bo.filetype, wins = #vim.api.nvim_list_wins() })
  signal "ready"
end, 600)
]]):format(root, showtabline, dir, session, vim.inspect(opts), vim.inspect(lines))

  vim.fn.writefile(vim.split(init, "\n"), dir .. "/init.lua")
  return dir
end

function M.start(session, lines, opts)
  local dir = M.setup_files(session, lines, opts)
  sh { "tmux", "kill-session", "-t", session }
  sh(("tmux new-session -d -s %s -x 100 -y 24 'nvim --clean -u %s/init.lua'"):format(session, dir))
  return dir
end

function M.wait(session, signal, seconds) sh(("timeout %d tmux wait-for %s-%s"):format(seconds or 15, signal, session)) end

function M.click(session, screenrow, screencol)
  local press = ("\27[<0;%d;%dM"):format(screencol, screenrow)
  local release = ("\27[<0;%d;%dm"):format(screencol, screenrow)
  sh(("tmux send-keys -t %s -H %s"):format(session, hex_of(press)))
  sh(("tmux send-keys -t %s -H %s"):format(session, hex_of(release)))
end

-- movimento sem botao pressionado: botao 35 no protocolo SGR
function M.move(session, screenrow, screencol)
  local motion = ("\27[<35;%d;%dM"):format(screencol, screenrow)
  sh(("tmux send-keys -t %s -H %s"):format(session, hex_of(motion)))
end

function M.type(session, keys) sh { "tmux", "send-keys", "-t", session, keys } end

-- seleciona linhas com o teclado e so retorna quando o Neovim confirma o estado
function M.select_lines(session, count)
  M.type(session, (":let g:toolbar_wait_line = %d\r"):format(count))
  M.type(session, "gg" .. (count > 1 and ("V" .. ("j"):rep(count - 1)) or "V"))
  M.wait(session, "visual")
end

function M.read(session, name)
  local path = dir_of(session) .. "/" .. name .. ".json"
  vim.wait(5000, function() return vim.uv.fs_stat(path) ~= nil end, 50)
  local content = vim.fn.readfile(path)
  if #content == 0 then return nil end
  return vim.json.decode(content[1])
end

function M.capture(session) return sh(("tmux capture-pane -t %s -p"):format(session)) end

function M.screen(session) return vim.split(M.capture(session), "\n") end

-- acha o texto na tela e devolve onde clicar (1-based), sem depender de calcular
-- bordas e offsets de janela flutuante. Faz retry porque o sinal do Neovim chega
-- antes de a tela ter sido desenhada.
function M.locate(session, needle, timeout)
  local found = nil
  vim.wait(timeout or 4000, function()
    for row, line in ipairs(M.screen(session)) do
      local start = line:find(needle, 1, true)
      if start then
        found = { row = row, col = start + 1, line = line }
        return true
      end
    end
    return false
  end, 150)
  return found
end

function M.stop(session) sh { "tmux", "kill-session", "-t", session } end

function M.region(regions, name)
  for _, region in ipairs(regions) do
    if region.name == name then return region end
  end
end

return M
