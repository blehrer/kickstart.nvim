---@module lazy.types
---@type LazyPluginSpec

--- Walk up from `start_path` until a directory containing playwright.config.ts
--- is found. Returns that directory, or falls back to vim.loop.cwd().
local function find_nearest_pw_dir(start_path)
  local dir = vim.fn.fnamemodify(start_path, ':h')
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
  return vim.loop.cwd()
end

--- Parse a .env file into a key→value table.
--- Handles: KEY=value, KEY="value", KEY='value', blank lines, # comments.
local function parse_dotenv(path)
  local result = {}
  if vim.fn.filereadable(path) ~= 1 then
    return result
  end
  for line in io.lines(path) do
    line = line:match('^%s*(.-)%s*$') -- trim
    if line ~= '' and not line:match('^#') then
      local key, val = line:match('^([%w_]+)%s*=%s*(.*)$')
      if key and val then
        -- strip surrounding quotes (single or double)
        val = val:match('^"(.*)"$') or val:match("^'(.*)'$") or val
        result[key] = val
      end
    end
  end
  return result
end

--- Read targets.e2e.configurations from a project.json next to `pw_dir`.
--- Returns a list of configuration names, e.g. {"local","int","qat"}.
local function get_nx_e2e_configurations(pw_dir)
  local project_json = pw_dir .. '/project.json'
  if vim.fn.filereadable(project_json) ~= 1 then
    return {}
  end
  local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(project_json), '\n'))
  if not ok or type(decoded) ~= 'table' then
    return {}
  end
  local configs = vim.tbl_get(decoded, 'targets', 'e2e', 'configurations')
  if type(configs) ~= 'table' then
    return {}
  end
  return vim.tbl_keys(configs)
end

local E2E_ENV_CACHE_FILE = vim.fn.stdpath('data') .. '/neotest-pw-e2e-env.json'

--- Path neotest-playwright callbacks should anchor on (set in build_spec wrapper).
local _pw_context_path = nil

--- Per playwright project dir, last chosen Nx e2e configuration name.
local _e2e_config_by_pw_dir = {}

local function load_e2e_env_cache()
  if vim.fn.filereadable(E2E_ENV_CACHE_FILE) ~= 1 then
    return {}
  end
  local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(E2E_ENV_CACHE_FILE), '\n'))
  if not ok or type(decoded) ~= 'table' then
    return {}
  end
  return decoded
end

local function save_e2e_env_cache()
  vim.fn.writefile({ vim.fn.json_encode(_e2e_config_by_pw_dir) }, E2E_ENV_CACHE_FILE)
end

_e2e_config_by_pw_dir = load_e2e_env_cache()

local function get_saved_e2e_config(pw_dir)
  return _e2e_config_by_pw_dir[pw_dir]
end

--- Resolve which file path to use when locating the Playwright project directory.
--- Summary runs focus the summary buffer, not the spec under test.
local function resolve_pw_anchor_path()
  if _pw_context_path and _pw_context_path ~= '' then
    return _pw_context_path
  end
  local buf = vim.api.nvim_buf_get_name(0)
  if buf ~= '' and not vim.bo.filetype:match('^neotest') then
    return buf
  end
  return vim.loop.cwd()
end

--- Load .env (credentials) and .env.{name} (environment) from `pw_dir`,
--- merge them, and apply to the neotest-playwright options.env table.
local function apply_pw_env(pw_dir, config_name)
  local base = parse_dotenv(pw_dir .. '/.env')
  local named = parse_dotenv(pw_dir .. '/.env.' .. config_name)
  -- named values win over base (matches Nx load order)
  local merged = vim.tbl_extend('force', base, named)
  local opts = require('neotest-playwright.adapter-options').options
  -- Replace env wholesale; build_spec adds PLAYWRIGHT_JSON_OUTPUT_NAME per run.
  opts.env = merged
  _e2e_config_by_pw_dir[pw_dir] = config_name
  save_e2e_env_cache()
  return merged
end

--- Re-apply persisted env for `pw_dir` when a saved configuration exists.
local function ensure_pw_env(pw_dir)
  local config_name = get_saved_e2e_config(pw_dir)
  if config_name then
    apply_pw_env(pw_dir, config_name)
  end
end

--- Run the playwright.config.ts through tsx and extract the resolved baseURL.
--- This evaluates the TypeScript so the `|| 'http://...'` fallback is returned
--- when BASE_URL is not set (e.g. for the `local` configuration).
local function extract_pw_config_base_url(pw_dir)
  local tsx_bin = vim.loop.cwd() .. '/node_modules/.bin/tsx'
  if vim.fn.filereadable(tsx_bin) ~= 1 then
    return nil
  end
  local abs_config = pw_dir .. '/playwright.config.ts'
  -- Write a tiny TS probe to a temp file; use an absolute import so the path
  -- is valid regardless of where the temp file lives.
  local tmp = vim.fn.tempname() .. '.ts'
  vim.fn.writefile({
    "import cfg from '" .. abs_config .. "';",
    "const c = cfg as any;",
    "process.stdout.write(String(c?.use?.baseURL ?? c?.webServer?.url ?? ''));",
  }, tmp)
  local result = vim.system({ tsx_bin, tmp }, { cwd = pw_dir }):wait()
  vim.fn.delete(tmp)
  if result.code == 0 and result.stdout and result.stdout ~= '' then
    return vim.trim(result.stdout)
  end
  return nil
end

--- Playwright CLI flags for the interactive picker.
--- `takes_value = true` flags prompt for a value after confirmation.
local PW_FLAGS = {
  { flag = '--debug',    label = 'debug    open Playwright Inspector',       takes_value = false },
  { flag = '--headed',   label = 'headed   show browser window',             takes_value = false },
  { flag = '--ui',       label = 'ui       Playwright UI mode',              takes_value = false },
  { flag = '--retries',  label = 'retries  max retry count',                 takes_value = true,  default = '0' },
  { flag = '--timeout',  label = 'timeout  ms per action  (0 = disable)',    takes_value = true,  default = '0' },
  { flag = '--workers',  label = 'workers  parallel workers',                takes_value = true,  default = '1' },
}

--- Active flag state: flag → true (boolean) or string value (value flags).
local _pw_flag_state = {}

local function sync_pw_flags_to_adapter()
  local args = {}
  for _, f in ipairs(PW_FLAGS) do
    local v = _pw_flag_state[f.flag]
    if v then
      table.insert(args, f.takes_value and (f.flag .. '=' .. v) or f.flag)
    end
  end
  require('neotest-playwright.adapter-options').options.extra_args = args
end

--- Display prefix for a flag entry: shows current active value.
local function flag_display(f)
  local v = _pw_flag_state[f.flag]
  if not v then
    return '○ ' .. f.label
  end
  if f.takes_value then
    return '● ' .. f.flag .. '=' .. v .. '  (' .. f.label:match('^%S+') .. ')'
  end
  return '● ' .. f.label
end

--- Telescope multi-select picker for Playwright CLI flags.
--- <Tab> marks entries; <CR> applies the marked set. Value flags prompt for
--- their value after confirmation. Opening the picker shows ●/○ current state.
local function pick_pw_flags()
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = 'Playwright flags  <Tab> mark · <CR> apply',
      finder = finders.new_table {
        results = PW_FLAGS,
        entry_maker = function(f)
          return {
            value = f,
            display = flag_display(f),
            ordinal = f.label,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local multi = picker:get_multi_selection()
          if #multi == 0 then
            local sel = action_state.get_selected_entry()
            if sel then
              multi = { sel }
            end
          end
          actions.close(prompt_bufnr)

          -- Confirmed set replaces previous state entirely.
          _pw_flag_state = {}
          for _, entry in ipairs(multi) do
            local f = entry.value
            if f.takes_value then
              -- Prompt for value; empty input skips the flag.
              local current = type(_pw_flag_state[f.flag]) == 'string' and _pw_flag_state[f.flag] or f.default
              local val = vim.fn.input(f.flag .. '=', current)
              if val ~= '' then
                _pw_flag_state[f.flag] = val
              end
            else
              _pw_flag_state[f.flag] = true
            end
          end

          sync_pw_flags_to_adapter()

          local active = {}
          for _, f in ipairs(PW_FLAGS) do
            local v = _pw_flag_state[f.flag]
            if v then
              table.insert(active, f.takes_value and (f.flag .. '=' .. v) or f.flag)
            end
          end
          local msg = #active > 0 and table.concat(active, ' ') or 'none'
          vim.notify('Playwright flags: ' .. msg, vim.log.levels.INFO)
        end)
        return true
      end,
    })
    :find()
end
--- Directly invoke pwa-node DAP for the current Playwright spec.
--- Bypasses neotest (no DAP strategy in neotest-playwright) and builds the
--- launch config from the buffer's pw_dir. Falls back to neotest DAP for
--- non-Playwright files (e.g. Jest).
local function run_pw_dap()
  local buf_path = vim.api.nvim_buf_get_name(0)
  local is_pw_spec = buf_path:find('%-e2e.+%.spec%.[tj]sx?$') ~= nil
    or buf_path:find('%-e2e.+%.test%.[tj]sx?$') ~= nil
  if not is_pw_spec then
    require('neotest').run.run { strategy = 'dap' }
    return
  end
  local pw_dir = find_nearest_pw_dir(buf_path)
  require('dap').run {
    type = 'pwa-node',
    request = 'launch',
    name = 'Playwright: debug ' .. vim.fn.fnamemodify(buf_path, ':t'),
    runtimeExecutable = 'npx',
    runtimeArgs = {
      'playwright',
      'test',
      '--debug',
      '--config',
      pw_dir .. '/playwright.config.ts',
      buf_path,
    },
    cwd = pw_dir,
    sourceMaps = true,
    resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
  }
end

--- Keybinding handler: pick an Nx e2e configuration for the current project,
--- load its .env files, and notify.
local function pick_e2e_env()
  local buf = vim.api.nvim_buf_get_name(0)
  if buf == '' or vim.bo.filetype:match('^neotest') then
    buf = resolve_pw_anchor_path()
  end
  local pw_dir = find_nearest_pw_dir(buf)
  local configs = get_nx_e2e_configurations(pw_dir)
  if #configs == 0 then
    vim.notify('No e2e configurations found in ' .. pw_dir .. '/project.json', vim.log.levels.WARN)
    return
  end
  table.sort(configs)
  local current = get_saved_e2e_config(pw_dir)
  local prompt = current and ('Select e2e environment (current: %s):'):format(current)
    or 'Select e2e environment:'
  vim.ui.select(configs, { prompt = prompt }, function(choice)
    if not choice then
      return
    end
    local merged = apply_pw_env(pw_dir, choice)
    local url = merged.BASE_URL
    if not url then
      -- No BASE_URL in dotenv (e.g. `local` config) — evaluate the TS config
      -- to get the hardcoded fallback value.
      url = extract_pw_config_base_url(pw_dir) or '(BASE_URL not resolved)'
    end
    vim.notify(string.format('e2e env → %s  %s', choice, url), vim.log.levels.INFO)
  end)
end

return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',

    -- {{{Adapters
    { 'haydenmeade/neotest-jest' },
    {
      'thenbe/neotest-playwright',
      dependencies = 'nvim-telescope/telescope.nvim',
      keys = {
        {
          '<leader>ta',
          function()
            require('neotest').playwright.attachment()
          end,
          desc = 'Test: launch attachment (trace/video)',
        },
        {
          '<leader>tp',
          '<cmd>NeotestPlaywrightProject<cr>',
          desc = 'Test: select Playwright project (browser)',
        },
        {
          '<leader>tP',
          pick_pw_flags,
          desc = 'Test: toggle Playwright CLI flags',
        },
        {
          '<leader>tx',
          '<cmd>NeotestPlaywrightRefresh<cr>',
          desc = 'Test: refresh Playwright test list',
        },
      },
    },
    -- }}}
  },
  lazy = true,
  config = function(_, opts)
    local pw_adapter = require('neotest-playwright').adapter {
      options = {
        persist_project_selection = true,
        enable_dynamic_test_discovery = true,

        -- Resolve the binary from the monorepo root (single install).
        get_playwright_binary = function()
          return vim.loop.cwd() .. '/node_modules/.bin/playwright'
        end,

        -- Resolve config and cwd from the active test position (see build_spec
        -- wrapper), not buffer 0 — summary runs keep the summary buffer focused.
        get_playwright_config = function()
          return find_nearest_pw_dir(resolve_pw_anchor_path()) .. '/playwright.config.ts'
        end,

        get_cwd = function()
          return find_nearest_pw_dir(resolve_pw_anchor_path())
        end,

        -- Skip directories that will never contain Playwright specs.
        filter_dir = function(name, _rel_path, _root)
          local skip = { node_modules = true, dist = true, ['.nx'] = true, ['.git'] = true, coverage = true }
          return not skip[name]
        end,

        -- Only treat files living under an *-e2e project as Playwright
        -- specs to avoid collisions with Jest .spec.ts files.
        is_test_file = function(file_path)
          return file_path:find('%-e2e.+%.spec%.[tj]sx?$') ~= nil
            or file_path:find('%-e2e.+%.test%.[tj]sx?$') ~= nil
        end,
      },
    }

    -- neotest-playwright's get_cwd/get_playwright_config take no args; anchor
    -- from the position tree so summary-panel runs use the correct project.
    local orig_build_spec = pw_adapter.build_spec
    pw_adapter.build_spec = function(args)
      local pos = args.tree:data()
      _pw_context_path = pos.path
      ensure_pw_env(find_nearest_pw_dir(pos.path))
      return orig_build_spec(args)
    end

    require('neotest').setup {
      adapters = {
        pw_adapter,

        require 'neotest-jest' {
          jestCommand = 'npm test --',
          jestConfigFile = 'custom.jest.config.ts',
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        },
      },
      consumers = {
        playwright = require('neotest-playwright.consumers').consumers,
      },
    }
  end,
  keys = {
    -- Run
    {
      '<leader>tr',
      function()
        require('neotest').run.run()
      end,
      desc = 'Test: run nearest',
    },
    {
      '<leader>tR',
      function()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      desc = 'Test: run file',
    },
    {
      '<leader>tl',
      function()
        require('neotest').run.run_last()
      end,
      desc = 'Test: run last',
    },
    {
      '<leader>tS',
      function()
        require('neotest').run.stop()
      end,
      desc = 'Test: stop nearest',
    },
    -- Debug (DAP)
    {
      '<leader>td',
      run_pw_dap,
      desc = 'Test: debug (Playwright: --debug+DAP · others: neotest DAP)',
    },
    {
      '<leader>tL',
      function()
        require('neotest').run.run_last { strategy = 'dap' }
      end,
      desc = 'Test: debug last (DAP)',
    },
    -- Output
    {
      '<leader>to',
      function()
        require('neotest').output.open { enter = true }
      end,
      desc = 'Test: show output',
    },
    {
      '<leader>tO',
      function()
        require('neotest').output_panel.toggle()
      end,
      desc = 'Test: toggle output panel',
    },
    -- Summary
    {
      '<leader>ts',
      function()
        require('neotest').summary.toggle()
      end,
      desc = 'Test: toggle summary panel',
    },
    -- Environment picker (Playwright / Nx e2e configurations)
    {
      '<leader>te',
      pick_e2e_env,
      desc = 'Test: select e2e environment (loads .env.{name})',
    },
    -- Watch (Jest)
    {
      '<leader>tw',
      "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>",
      desc = 'Test: Jest watch',
    },
  },
}
--- vim: ts=2 sts=2 sw=2 et foldmethod=marker
