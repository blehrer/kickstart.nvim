local workspace = require('nx.workspace')
local cli = require('nx.playwright_cli')

local M = {}

M.pw_context_path = nil
M.active_session = nil

local function in_project(path, nx_root)
  if not nx_root or nx_root == '' then
    return true
  end
  local root = vim.fn.fnamemodify(nx_root, ':p')
  local norm = vim.fn.fnamemodify(path, ':p')
  return norm:find(root, 1, true) ~= nil
end

local E2E_ENV_CACHE = vim.fn.stdpath('data') .. '/neotest-pw-e2e-env.json'
local e2e_config_by_pw_dir = {}

local function load_e2e_cache()
  if vim.fn.filereadable(E2E_ENV_CACHE) ~= 1 then
    return {}
  end
  local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(E2E_ENV_CACHE), '\n'))
  return ok and type(decoded) == 'table' and decoded or {}
end

local function save_e2e_cache()
  vim.fn.writefile({ vim.fn.json_encode(e2e_config_by_pw_dir) }, E2E_ENV_CACHE)
end

e2e_config_by_pw_dir = load_e2e_cache()

function M.find_pw_dir(start_path)
  local dir = vim.fn.fnamemodify(start_path or vim.loop.cwd(), ':p')
  if vim.fn.isdirectory(dir) ~= 1 then
    dir = vim.fn.fnamemodify(dir, ':h')
  end
  while dir ~= '/' and dir ~= '' do
    if vim.fn.filereadable(dir .. '/playwright.config.ts') == 1 then
      return dir
    end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then
      break
    end
    dir = parent
  end
  return workspace.root() or vim.loop.cwd()
end

function M.resolve_anchor_path()
  if M.pw_context_path and M.pw_context_path ~= '' then
    return M.pw_context_path
  end
  local buf = vim.api.nvim_buf_get_name(0)
  if buf ~= '' and not vim.bo.filetype:match('^neotest') then
    return buf
  end
  return vim.loop.cwd()
end

function M.is_pw_spec(path)
  if not path:match('%.[tj]sx?$') then
    return false
  end
  if not (path:match('%.spec%.[tj]sx?$') or path:match('%.test%.[tj]sx?$')) then
    return false
  end
  return path:find('%-e2e', 1, true) ~= nil or path:find('/e2e/', 1, true) ~= nil
end

function M.spec_files(nx_root)
  if not nx_root or vim.fn.isdirectory(nx_root) ~= 1 then
    return {}
  end
  local specs = {}
  local seen = {}
  for _, pat in ipairs({ '**/*.spec.ts', '**/*.spec.tsx', '**/*.test.ts', '**/*.test.tsx' }) do
    for _, path in ipairs(vim.fn.globpath(nx_root, pat, false, true)) do
      if not seen[path] and M.is_pw_spec(path) then
        seen[path] = true
        specs[#specs + 1] = path
      end
    end
  end
  table.sort(specs)
  return specs
end

function M.e2e_configurations(pw_dir)
  local data = workspace.read_json(pw_dir .. '/project.json')
  local configs = data and vim.tbl_get(data, 'targets', 'e2e', 'configurations')
  if type(configs) ~= 'table' then
    return {}
  end
  local names = vim.tbl_keys(configs)
  table.sort(names)
  return names
end

local function parse_dotenv(path)
  local result = {}
  if vim.fn.filereadable(path) ~= 1 then
    return result
  end
  for line in io.lines(path) do
    line = line:match('^%s*(.-)%s*$')
    if line ~= '' and not line:match('^#') then
      local key, val = line:match('^([%w_]+)%s*=%s*(.*)$')
      if key and val then
        val = val:match('^"(.*)"$') or val:match("^'(.*)'$") or val
        result[key] = val
      end
    end
  end
  return result
end

function M.apply_env(pw_dir, config_name)
  local merged = vim.tbl_extend('force', parse_dotenv(pw_dir .. '/.env'), parse_dotenv(pw_dir .. '/.env.' .. config_name))
  require('neotest-playwright.adapter-options').options.env = merged
  e2e_config_by_pw_dir[pw_dir] = config_name
  save_e2e_cache()
  return merged
end

function M.ensure_env(pw_dir)
  local name = e2e_config_by_pw_dir[pw_dir]
  if name then
    M.apply_env(pw_dir, name)
  end
end

function M.saved_e2e_config(pw_dir)
  return e2e_config_by_pw_dir[pw_dir]
end

local function sync_pw_flags(args)
  require('neotest-playwright.adapter-options').options.extra_args = args or {}
end

function M.pick_flags()
  cli.pick_flags(function(args)
    sync_pw_flags(args)
    local msg = #args > 0 and table.concat(args, ' ') or 'none'
    vim.notify('Playwright flags: ' .. msg, vim.log.levels.INFO)
  end)
end

local function dap_runtime_args(cmd)
  local args = { 'playwright' }
  local saw_test = false
  for i = 2, #cmd do
    local part = cmd[i]
    if part == 'test' then
      args[#args + 1] = 'test'
      args[#args + 1] = '--debug'
      saw_test = true
    elseif not part:match('^%-%-reporter=') then
      args[#args + 1] = part
    end
  end
  if not saw_test then
    table.insert(args, 2, 'test')
    table.insert(args, 3, '--debug')
  end
  return args
end

local function dap_strategy(spec, label)
  return {
    type = 'pwa-node',
    request = 'launch',
    name = label,
    runtimeExecutable = 'npx',
    runtimeArgs = dap_runtime_args(spec.command),
    cwd = spec.cwd,
    env = spec.env,
    sourceMaps = true,
    resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
  }
end

local function attach_dap_strategy(spec, label)
  if spec[1] then
    for _, item in ipairs(spec) do
      item.strategy = dap_strategy(item, label)
    end
    return spec
  end
  spec.strategy = dap_strategy(spec, label)
  return spec
end

function M.wrap_adapter(adapter)
  local orig = adapter.build_spec
  adapter.build_spec = function(args)
    local pos = args.tree:data()
    local session = M.active_session
    if session and session.nx_root and in_project(pos.path, session.nx_root) then
      M.pw_context_path = session.nx_root
      if session.env then
        M.apply_env(session.nx_root, session.env)
      else
        M.ensure_env(session.nx_root)
      end
      local opts = require('neotest-playwright.adapter-options').options
      opts.extra_args = session:extra_parts()
      opts.projects = session.pw_project and { session.pw_project } or {}
    else
      M.pw_context_path = pos.path
      M.ensure_env(M.find_pw_dir(pos.path))
    end
    local spec = orig(args)
    if spec and args.strategy == 'dap' then
      local label = 'Playwright: ' .. vim.fn.fnamemodify(pos.path, ':t')
      attach_dap_strategy(spec, label)
    end
    return spec
  end
  return adapter
end

function M.adapter_options()
  return {
    persist_project_selection = true,
    enable_dynamic_test_discovery = true,
    experimental = { telescope = { enabled = false } },
    get_playwright_binary = function()
      return (workspace.root() or vim.loop.cwd()) .. '/node_modules/.bin/playwright'
    end,
    get_playwright_config = function()
      return M.find_pw_dir(M.resolve_anchor_path()) .. '/playwright.config.ts'
    end,
    get_cwd = function()
      return M.find_pw_dir(M.resolve_anchor_path())
    end,
    filter_dir = function(name)
      local skip = { node_modules = true, dist = true, ['.nx'] = true, ['.git'] = true, coverage = true }
      return not skip[name]
    end,
    is_test_file = M.is_pw_spec,
  }
end

--- Sync wizard session into neotest-playwright adapter options.
function M.apply_session(session)
  M.active_session = session
  if session.nx_root then
    M.pw_context_path = session.nx_root
  end
  if session.nx_root and session.env then
    M.apply_env(session.nx_root, session.env)
  elseif session.nx_root then
    M.ensure_env(session.nx_root)
  end
  local opts = require('neotest-playwright.adapter-options').options
  opts.extra_args = session:extra_parts()
  opts.projects = session.pw_project and { session.pw_project } or {}
end

function M.clear_session()
  M.active_session = nil
end

function M.pick_e2e_env()
  local pw_dir = M.find_pw_dir(M.resolve_anchor_path())
  local configs = M.e2e_configurations(pw_dir)
  if #configs == 0 then
    vim.notify('No targets.e2e.configurations in ' .. pw_dir .. '/project.json', vim.log.levels.WARN)
    return
  end

  local current = e2e_config_by_pw_dir[pw_dir]
  local prompt = current and ('e2e env (current: ' .. current .. '):') or 'e2e env:'
  Snacks.picker.select(configs, { prompt = prompt }, function(choice)
    if not choice then
      return
    end
    local merged = M.apply_env(pw_dir, choice)
    local url = merged.BASE_URL or '(no BASE_URL in .env)'
    vim.notify('e2e → ' .. choice .. '  ' .. url, vim.log.levels.INFO)
  end)
end

function M.run_dap(opts)
  opts = opts or {}
  local buf_path = opts.path or vim.api.nvim_buf_get_name(0)
  if not M.is_pw_spec(buf_path) then
    require('neotest').run.run({ strategy = 'dap' })
    return
  end

  local pw_dir = M.find_pw_dir(buf_path)
  local adapter_opts = require('neotest-playwright.adapter-options').options
  local build_command = require('neotest-playwright.build-command').buildCommand
  local cmd = build_command({
    bin = adapter_opts.get_playwright_binary(),
    config = adapter_opts.get_playwright_config(),
    projects = adapter_opts.projects,
    testFilter = buf_path,
  }, adapter_opts.extra_args)

  require('dap').run({
    type = 'pwa-node',
    request = 'launch',
    name = 'Playwright: ' .. vim.fn.fnamemodify(buf_path, ':t'),
    runtimeExecutable = 'npx',
    runtimeArgs = dap_runtime_args(cmd),
    cwd = pw_dir,
    env = adapter_opts.env,
    sourceMaps = true,
    resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
  })
end

return M
