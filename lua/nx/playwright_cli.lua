local workspace = require('nx.workspace')

local M = {}

local CACHE_FILE = vim.fn.stdpath('data') .. '/playwright-cli-options.json'
local COMPLETE_HINT = 'Tab or ^X^O for Playwright flags'

---@class PlaywrightCliOption
---@field flag string
---@field flags string[]
---@field desc string
---@field takes_value boolean

function M.minor_version(full)
  local major, minor = (full or ''):match('(%d+)%.(%d+)')
  return major and minor and (major .. '.' .. minor) or (full or 'unknown')
end

local function pw_cmd(args)
  local ws = workspace.root() or vim.loop.cwd()
  local bin = ws .. '/node_modules/.bin/playwright'
  if vim.fn.executable(bin) == 1 then
    return vim.list_extend({ bin }, args)
  end
  return vim.list_extend({ 'npx', 'playwright' }, args)
end

local function run_playwright(args)
  return vim.system(pw_cmd(args), { text = true, env = vim.fn.environ() }):wait()
end

function M.current_version()
  local result = run_playwright({ '--version' })
  if result.code ~= 0 or not result.stdout then
    return nil, nil
  end
  local full = vim.trim(result.stdout):match('[%d%.]+')
  return full, M.minor_version(full)
end

---@param help string
---@return PlaywrightCliOption[]
function M.parse_help(help)
  local options = {}
  local seen = {}
  local in_options = false

  for line in help:gmatch('[^\r\n]+') do
    if line:match('^Options:') then
      in_options = true
    elseif in_options then
      if line:match('^%[') then
        break
      end
      if not line:match('^%s+-') then
        goto continue
      end

      local flags_part, desc = line:match('^%s+(.-)%s%s+(.+)$')
      if not flags_part or not desc then
        goto continue
      end

      local flags = {}
      for token in flags_part:gmatch('[^,%s]+') do
        if token:sub(1, 1) == '-' then
          flags[#flags + 1] = token
        end
      end

      local primary = nil
      for _, f in ipairs(flags) do
        if f:sub(1, 2) == '--' then
          primary = f
          break
        end
      end
      primary = primary or flags[1]

      if primary and not seen[primary] then
        seen[primary] = true
        options[#options + 1] = {
          flag = primary,
          flags = flags,
          desc = vim.trim(desc),
          takes_value = primary:find('[<=%[]') ~= nil,
        }
      end
    end
    ::continue::
  end

  table.sort(options, function(a, b)
    return a.flag < b.flag
  end)
  return options
end

local function read_cache()
  if vim.fn.filereadable(CACHE_FILE) ~= 1 then
    return nil
  end
  local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(CACHE_FILE), '\n'))
  return ok and decoded or nil
end

local function write_cache(data)
  vim.fn.writefile({ vim.fn.json_encode(data) }, CACHE_FILE)
end

function M.refresh()
  local full, minor = M.current_version()
  if not full then
    return nil, 'playwright not found (install in monorepo root)'
  end

  local help = run_playwright({ 'test', '--help' })
  if help.code ~= 0 or not help.stdout then
    return nil, 'playwright test --help failed'
  end

  local options = M.parse_help(help.stdout)
  if #options == 0 then
    return nil, 'no options parsed from playwright test --help'
  end

  local data = {
    minor_version = minor,
    full_version = full,
    recorded_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    options = options,
  }
  write_cache(data)
  return data
end

function M.get()
  local cached = read_cache()
  local full, minor = M.current_version()

  if full and cached and cached.minor_version == minor and type(cached.options) == 'table' and #cached.options > 0 then
    return cached
  end

  if cached and not full then
    return cached
  end

  local fresh, err = M.refresh()
  if fresh then
    return fresh
  end

  if cached then
    vim.notify('playwright CLI cache stale: ' .. (err or 'refresh failed'), vim.log.levels.WARN)
    return cached
  end

  return { minor_version = minor or 'unknown', full_version = full, options = {} }
end

local function findstart_col(line, col)
  local before = line:sub(1, col)
  local flag_start = before:match('.*()(%-%-[%w%-]*)$') or before:match('.*()(%-[%w%-]*)$')
  if flag_start then
    return flag_start - 1
  end
  local word_start = before:match('.*()(%S*)$')
  if word_start then
    return word_start - 1
  end
  return col
end

--- Omnifunc for Snacks.input — ^X^O or Tab.
function M.complete(findstart, base, _line, _col, _shift)
  if findstart == 1 then
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    return findstart_col(line, col + 1)
  end

  local items = {}
  local seen = {}
  for _, o in ipairs(M.get().options) do
    for _, flag in ipairs(o.flags) do
      if not seen[flag] and (base == '' or flag:find(base, 1, true) == 1) then
        seen[flag] = true
        items[#items + 1] = flag
      end
    end
  end
  table.sort(items)
  return items
end

function M.complete_hint()
  return COMPLETE_HINT
end

function M.input_opts(extra)
  return vim.tbl_extend('force', {
    title = 'Playwright args · ' .. COMPLETE_HINT,
  }, extra or {})
end

--- Snacks.input wrapper with Playwright flag completion.
function M.input(opts, on_confirm)
  local complete = 'v:lua.NxPlaywrightComplete'
  opts = vim.tbl_extend('force', M.input_opts(opts), {
    win = {
      -- Snacks.input resolve always wins omnifunc last; patch opts.bo so update() keeps ours.
      on_buf = function(win)
        win.opts.bo.omnifunc = complete
        win.opts.bo.completefunc = complete
        vim.bo[win.buf].omnifunc = complete
        vim.bo[win.buf].completefunc = complete
      end,
      keys = {
        ['<Tab>'] = {
          function()
            if vim.fn.pumvisible() == 1 then
              return '<c-n>'
            end
            return '<c-x><c-o>'
          end,
          mode = 'i',
          expr = true,
        },
        ['<C-x><C-o>'] = {
          function()
            return vim.fn.pumvisible() == 0 and '<c-x><c-o>' or ''
          end,
          mode = 'i',
          expr = true,
        },
      },
    },
  })

  return Snacks.input(opts, on_confirm)
end

function M.label(option)
  local name = option.flag:gsub('%s+', ' ')
  if #option.desc > 72 then
    return name .. '  ' .. option.desc:sub(1, 69) .. '…'
  end
  return name .. '  ' .. option.desc
end

function M.pick_flags(on_done)
  local data = M.get()
  if #data.options == 0 then
    vim.notify('No Playwright CLI options cached — is playwright installed?', vim.log.levels.WARN)
    return
  end

  local select_multiple = require('neotest-playwright.select-multiple').selectMultiple
  local labels = vim.tbl_map(function(o)
    return M.label(o)
  end, data.options)
  labels[#labels + 1] = 'Done'

  local by_label = {}
  for _, o in ipairs(data.options) do
    by_label[M.label(o)] = o
  end

  local selected = select_multiple({
    prompt = 'Playwright flags · toggle then Done (<leader>tP)',
    choices = labels,
    initial = 'none',
  })

  local args = {}
  for _, label in ipairs(selected) do
    local option = by_label[label]
    if option then
      if option.takes_value then
        local val = vim.fn.input(option.flag .. '=', '')
        if val ~= '' then
          args[#args + 1] = option.flag .. '=' .. val
        end
      else
        args[#args + 1] = option.flag
      end
    end
  end

  if on_done then
    on_done(args)
  end
  return args
end

-- getcompletion() needs a global; require() in the spec does not work
_G.NxPlaywrightComplete = function(findstart, base, line, col, shift)
  return M.complete(findstart, base, line, col, shift)
end

if os.getenv('NVIM_PW_CLI_SELF_CHECK') == '1' then
  assert(M.minor_version('1.62.0') == '1.62')
  local sample = [[
Options:
  --debug [mode]                   Run tests with Playwright Inspector
  -g, --grep <grep>                Only run tests matching
]]
  assert(#M.parse_help(sample) >= 2)
  assert(M.complete(0, '--deb')[1] == '--debug')
end

return M
