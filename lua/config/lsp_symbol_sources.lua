--- Workspace LSP symbol sources: detect relevant servers, toggle inclusion, enable + wait.
local M = {}

local STATE_FILE = vim.fn.stdpath('data') .. '/lsp-symbol-sources.json'
local ATTACH_TIMEOUT_MS = 60000
local SETTLE_TIMEOUT_MS = 30000

local FT_GLOB = {
  typescript = '*.ts',
  typescriptreact = '*.tsx',
  javascript = '*.js',
  javascriptreact = '*.jsx',
  python = '*.py',
  kotlin = '*.kt',
  java = '*.java',
  lua = '*.lua',
  bash = '*.sh',
  sh = '*.sh',
  zsh = '*.zsh',
  dockerfile = 'Dockerfile',
  groovy = '*.gradle',
}

--- File extensions for vim.fs.find (faster than ** globs; skips node_modules).
local FT_EXT = {
  typescript = { 'ts' },
  typescriptreact = { 'tsx' },
  javascript = { 'js' },
  javascriptreact = { 'jsx' },
}

--- Extra root hints when the LSP workspace root (e.g. .git) is not where sources live.
local PROBE_ROOT_MARKERS = {
  ts_ls = {
    'tsconfig.json',
    'jsconfig.json',
    'package.json',
    'package-lock.json',
    'pnpm-lock.yaml',
    'yarn.lock',
  },
}

local SKIP_DIR = {
  ['.git'] = true,
  node_modules = true,
  dist = true,
  build = true,
  target = true,
}

local function default_markers()
  local star = vim.lsp.config['*']
  return (star and star.root_markers) or { '.git' }
end

local function workspace_root()
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  return vim.fs.root(cwd, default_markers()) or cwd
end

local function load_all_state()
  local path = STATE_FILE
  if not vim.uv.fs_stat(path) then
    return {}
  end
  local raw = vim.fn.readfile(path)
  if #raw == 0 then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, table.concat(raw, '\n'))
  return ok and type(decoded) == 'table' and decoded or {}
end

local function save_workspace_state(included)
  local all = load_all_state()
  all[workspace_root()] = included
  vim.fn.writefile({ vim.json.encode(all) }, STATE_FILE)
end

local function load_workspace_included()
  local all = load_all_state()
  return all[workspace_root()] or {}
end

local function configured_names()
  return require('config.lsp').ensure_installed
end

local function server_config(name)
  return vim.lsp.config[name]
end

local function symbol_clients(name)
  local out = {}
  for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
    if client:supports_method('workspace/symbol') then
      out[#out + 1] = client
    end
  end
  return out
end

local function path_skipped(path)
  for segment in path:gmatch('/([^/]+)/') do
    if SKIP_DIR[segment] then
      return true
    end
  end
  return false
end

local function probe_roots(name, lsp_root)
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local seen = {}
  local roots = {}
  local function add(r)
    if not r then
      return
    end
    r = vim.fs.normalize(r)
    if seen[r] then
      return
    end
    seen[r] = true
    roots[#roots + 1] = r
  end
  add(cwd)
  local extra = PROBE_ROOT_MARKERS[name]
  if extra then
    add(vim.fs.root(cwd, extra))
  end
  add(lsp_root)
  add(workspace_root())
  return roots
end

local function extensions_for_cfg(cfg)
  local exts = {}
  local seen = {}
  for _, ft in ipairs(cfg.filetypes or {}) do
    local list = FT_EXT[ft]
    if list then
      for _, ext in ipairs(list) do
        if not seen[ext] then
          seen[ext] = true
          exts[#exts + 1] = ext
        end
      end
    end
  end
  return exts
end

local function find_by_extensions(search_path, exts)
  if #exts == 0 then
    return nil
  end
  local ext_set = {}
  for _, ext in ipairs(exts) do
    ext_set[ext] = true
  end
  return vim.fs.find(function(name, full)
    if path_skipped(full) then
      return false
    end
    local ext = name:match('%.([^%.]+)$')
    return ext and ext_set[ext] or false
  end, { path = search_path, limit = 1, type = 'file' })[1]
end

local function glob_probe(root, cfg)
  local patterns = {}
  for _, ft in ipairs(cfg.filetypes or {}) do
    local pat = FT_GLOB[ft]
    if pat then
      patterns[#patterns + 1] = pat
    end
  end
  for _, pat in ipairs(patterns) do
    if pat:find('%*') then
      local hits = vim.fn.glob(root .. '/**/' .. pat, true, true)
      for _, hit in ipairs(hits) do
        if not path_skipped(hit) then
          return hit
        end
      end
    else
      local path = root .. '/' .. pat
      if vim.uv.fs_stat(path) then
        return path
      end
    end
  end
  return nil
end

local function probe_file(name, lsp_root, cfg)
  local exts = extensions_for_cfg(cfg)
  for _, root in ipairs(probe_roots(name, lsp_root)) do
    local hit = find_by_extensions(root, exts)
    if hit then
      return hit
    end
    hit = glob_probe(root, cfg)
    if hit then
      return hit
    end
  end
  return nil
end

local function load_probe_buffer(path)
  local bufnr = vim.fn.bufadd(path)
  vim.fn.bufload(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd.doautoall('nvim.lsp.enable FileType')
  end)
end

---@class kickstart.lsp_symbol_sources.Server
---@field name string
---@field root string
---@field enabled boolean
---@field attached boolean
---@field included boolean

function M.discover()
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local servers = {} ---@type kickstart.lsp_symbol_sources.Server[]
  for _, name in ipairs(configured_names()) do
    local cfg = server_config(name)
    if cfg then
      local markers = cfg.root_markers or default_markers()
      local root = vim.fs.root(cwd, markers)
      if root then
        servers[#servers + 1] = {
          name = name,
          root = root,
          enabled = vim.lsp.is_enabled(name),
          attached = #symbol_clients(name) > 0,
        }
      end
    end
  end
  table.sort(servers, function(a, b)
    return a.name < b.name
  end)
  return servers
end

local function default_included(servers)
  local included = {}
  for _, s in ipairs(servers) do
    if s.enabled and s.attached then
      included[s.name] = true
    end
  end
  return included
end

function M.included_map()
  local servers = M.discover()
  local saved = load_workspace_included()
  local included = default_included(servers)
  for name, on in pairs(saved) do
    included[name] = on
  end
  for _, s in ipairs(servers) do
    s.included = included[s.name] == true
  end
  return included, servers
end

function M.enable_and_attach(name, root)
  if not vim.lsp.is_enabled(name) then
    vim.lsp.enable(name)
  end
  if #symbol_clients(name) > 0 then
    return true
  end
  local cfg = server_config(name)
  if not cfg then
    return false
  end
  local path = probe_file(name, root, cfg)
  if not path then
    local exts = extensions_for_cfg(cfg)
    local hint = #exts > 0 and table.concat(exts, '/') or 'matching'
    vim.notify(
      ('LSP %s: no %s source file under cwd or workspace — open one, then retry'):format(name, hint),
      vim.log.levels.WARN
    )
    return false
  end
  load_probe_buffer(path)
  local ok = vim.wait(ATTACH_TIMEOUT_MS, function()
    return #symbol_clients(name) > 0
  end, 100)
  return ok
end

local function settle_client(client)
  local done = false
  client:request('workspace/symbol', { query = '' }, function(err)
    done = not err
  end)
  vim.wait(SETTLE_TIMEOUT_MS, function()
    return done
  end, 50)
  return done
end

function M.prepare_clients(included)
  local root = workspace_root()
  local clients = {}
  for name, on in pairs(included) do
    if not on then
      goto continue
    end
    local existing = symbol_clients(name)
    if #existing > 0 then
      for _, c in ipairs(existing) do
        clients[#clients + 1] = c
      end
      goto continue
    end
    if not M.enable_and_attach(name, root) then
      vim.notify(('LSP %s did not attach (symbol search skipped)'):format(name), vim.log.levels.WARN)
      goto continue
    end
    for _, c in ipairs(symbol_clients(name)) do
      settle_client(c)
      clients[#clients + 1] = c
    end
    ::continue::
  end
  return clients
end

local function status_text(s)
  local parts = {}
  parts[#parts + 1] = s.enabled and 'enabled' or 'disabled'
  parts[#parts + 1] = s.attached and 'attached' or 'detached'
  return table.concat(parts, ', ')
end

local function format_source(item)
  local mark = item.included and '󰄲' or ' '
  local a = Snacks.picker.util.align
  return {
    { a(mark, 2) },
    { a(item.name, 18) },
    { ' ' },
    { item.status, 'SnacksPickerDimmed' },
  }
end

function M.manage()
  local included = select(1, M.included_map())
  local servers = M.discover()
  if #servers == 0 then
    vim.notify('No LSP servers match this workspace (root markers)', vim.log.levels.INFO)
    return
  end

  local ctx = { included = vim.deepcopy(included) }

  local function build_items()
    local items = {}
    for _, s in ipairs(M.discover()) do
      local on = ctx.included[s.name] == true
      items[#items + 1] = {
        name = s.name,
        root = s.root,
        included = on,
        enabled = s.enabled,
        attached = s.attached,
        status = status_text(s),
        text = ('%s %s'):format(on and '[x]' or '[ ]', s.name),
      }
    end
    return items
  end

  Snacks.picker({
    title = 'LSP symbol sources',
    finder = build_items,
    format = format_source,
    confirm = function(picker)
      save_workspace_state(ctx.included)
      picker:close()
    end,
    actions = {
      toggle = function(picker)
        local item = picker:current()
        if not item then
          return
        end
        ctx.included[item.name] = not ctx.included[item.name]
        save_workspace_state(ctx.included)
        picker:refresh()
      end,
      enable = function(picker)
        local item = picker:current()
        if not item then
          return
        end
        if M.enable_and_attach(item.name, item.root) then
          ctx.included[item.name] = true
          save_workspace_state(ctx.included)
          vim.notify(('LSP %s ready for symbol search'):format(item.name), vim.log.levels.INFO)
        else
          vim.notify(('LSP %s failed to attach'):format(item.name), vim.log.levels.ERROR)
        end
        picker:refresh()
      end,
    },
    win = {
      input = {
        keys = {
          ['<Tab>'] = { 'toggle', mode = 'n', desc = 'Toggle include' },
          e = { 'enable', mode = 'n', desc = 'Enable LSP and include' },
        },
      },
      list = {
        keys = {
          ['<Tab>'] = { 'toggle', mode = 'n', desc = 'Toggle include' },
          e = { 'enable', mode = 'n', desc = 'Enable LSP and include' },
        },
      },
    },
  })
end

function M.search()
  local included = select(1, M.included_map())
  local any = false
  for _, on in pairs(included) do
    if on then
      any = true
      break
    end
  end
  if not any then
    vim.notify('No LSP sources included — pick servers first (<leader>sL)', vim.log.levels.INFO)
    M.manage()
    return
  end

  local clients = M.prepare_clients(included)
  if #clients == 0 then
    vim.notify('No LSP clients ready for workspace symbols', vim.log.levels.WARN)
    M.manage()
    return
  end

  local lsp = require('snacks.picker.source.lsp')
  local symbol_filter = require('snacks.picker.config.sources').lsp_workspace_symbols.filter

  Snacks.picker({
    title = 'Workspace symbols',
    format = 'lsp_symbol',
    live = true,
    workspace = true,
    tree = false,
    filter = symbol_filter,
    finder = function(_opts, ctx)
      local buf = ctx.filter.current_buf
      local filter = symbol_filter[vim.bo[buf].filetype] or symbol_filter.default
      local bufmap = lsp.bufmap()
      local function want(kind)
        kind = kind or 'Unknown'
        return type(filter) == 'boolean' or vim.tbl_contains(filter, kind)
      end
      ---@async
      ---@param cb async fun(item: snacks.picker.finder.Item)
      return function(cb)
        local query = ctx.filter.search or ''
        for _, client in ipairs(clients) do
          lsp.request(client, 'workspace/symbol', function()
            return { query = query }
          end, function(c, result)
            local items = lsp.results_to_items(c, result or {}, {
              text_with_file = true,
              filter = function(sym)
                return want(lsp.symbol_kind(sym.kind))
              end,
            })
            for _, item in ipairs(items) do
              item.text = ('[%s] %s'):format(c.name, item.text)
              item.buf = bufmap[item.file]
              cb(item)
            end
          end)
        end
      end
    end,
    confirm = 'jump',
    jump = { tagstack = true, reuse_win = true },
  })
end

return M
