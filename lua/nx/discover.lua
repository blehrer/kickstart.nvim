local workspace = require('nx.workspace')

local M = {}

--- Extend this table to add more Nx target menus later.
M.kinds = {
  { target = 'e2e', label = 'E2E (Playwright)' },
  { target = 'test', label = 'Unit / integration test' },
}

local CACHE_DIR = vim.fn.stdpath('data') .. '/nx-projects'
local NOTIFY_ID = 'nx-project-list'
local list_cache = {}
local detail_cache = {}
local path_index = {}
local nx_unavailable = {}
local pw_cache = {}
local inflight = {}

local function notify_status(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { id = NOTIFY_ID, title = 'Nx' })
end

local function emit_status(token, msg, level)
  notify_status(msg, level)
  local job = inflight[token]
  if not job then
    return
  end
  for _, picker in ipairs(job.pickers) do
    if picker and not picker.closed then
      picker.title = msg
      picker:update_titles()
    end
  end
end

local function nx_mtime(root)
  return vim.fn.getftime(root .. '/nx.json')
end

local function cache_token(remote_id, target)
  return (remote_id or '') .. '\0' .. (target or '*')
end

local function mem_key(root, target)
  local remote_id = workspace.git_remote_id(root)
  return cache_token(remote_id, target) .. '\0' .. tostring(nx_mtime(root))
end

local function disk_path(remote_id, target)
  local hash = vim.fn.sha256(cache_token(remote_id, target))
  return CACHE_DIR .. '/' .. hash:sub(1, 16) .. '.json'
end

local function names_to_stubs(names)
  local stubs = {}
  for _, name in ipairs(names) do
    stubs[#stubs + 1] = { name = name }
  end
  return stubs
end

local function read_disk_cache(remote_id, target, mtime)
  local path = disk_path(remote_id, target)
  if vim.fn.filereadable(path) ~= 1 then
    return nil, false
  end
  local ok, data = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), '\n'))
  if not ok or type(data) ~= 'table' then
    return nil, false
  end
  if data.remote_id ~= remote_id then
    return nil, false
  end
  if (target or '*') ~= (data.target or '*') then
    return nil, false
  end
  if type(data.names) ~= 'table' or #data.names == 0 then
    return nil, false
  end
  local stale = tonumber(data.nx_mtime) ~= tonumber(mtime)
  return names_to_stubs(data.names), stale
end

local function write_disk_cache(remote_id, target, mtime, names)
  vim.fn.mkdir(CACHE_DIR, 'p')
  local payload = {
    remote_id = remote_id,
    target = target,
    nx_mtime = mtime,
    names = names,
    recorded_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
  }
  vim.fn.writefile({ vim.fn.json_encode(payload) }, disk_path(remote_id, target))
end

local function run_nx(root, args, timeout_ms)
  return vim.system(workspace.nx_cmd(root, args), {
    cwd = root,
    text = true,
    env = vim.fn.environ(),
    timeout = timeout_ms or 15000,
  }):wait()
end

local function decode_project_names(stdout)
  local ok, decoded = pcall(vim.fn.json_decode, stdout)
  if not ok then
    return nil
  end
  if type(decoded) == 'table' and decoded[1] then
    return decoded
  end
  if type(decoded) == 'table' then
    return vim.tbl_keys(decoded)
  end
  return nil
end

--- Fast name list via `nx show projects` (uses nx daemon when running).
local function nx_project_names(root, target)
  local args = { 'show', 'projects', '--json' }
  if target then
    args[#args + 1] = '--with-target=' .. target
  end

  local result = run_nx(root, args)
  if result.code ~= 0 or not result.stdout or result.stdout == '' then
    return nil
  end
  return decode_project_names(result.stdout)
end

--- ponytail: scoped glob fallback — apps/libs only, not whole repo
local function scoped_project_paths(root)
  local nx = workspace.read_json(root .. '/nx.json') or {}
  local apps = vim.tbl_get(nx, 'workspaceLayout', 'appsDir') or 'apps'
  local libs = vim.tbl_get(nx, 'workspaceLayout', 'libsDir') or 'libs'
  local paths = {}

  for _, dir in ipairs({ apps, libs }) do
    local base = root .. '/' .. dir
    if vim.fn.isdirectory(base) == 1 then
      for _, path in ipairs(vim.fn.globpath(base, '**/project.json', false, true)) do
        if not path:find('/node_modules/', 1, true) then
          paths[#paths + 1] = path
        end
      end
    end
  end

  table.sort(paths)
  return paths
end

local function index_key(root)
  return mem_key(root, nil) .. '\0paths'
end

local function get_path_index(root)
  return path_index[index_key(root)]
end

--- Scan apps/libs project.json; cache name → path for fast hydrate.
local function scan_projects(root, target)
  local names = {}
  local index = {}
  for _, path in ipairs(scoped_project_paths(root)) do
    local data = workspace.read_json(path)
    if data and data.name then
      index[data.name] = path
      if not target or vim.tbl_get(data, 'targets', target) then
        names[#names + 1] = data.name
      end
    end
  end
  table.sort(names)
  path_index[index_key(root)] = index
  return names
end

local function fallback_project_names(root, target)
  return scan_projects(root, target)
end

local function hydrate_from_index(stub, root, dkey)
  local index = get_path_index(root)
  local path = index and index[stub.name]
  if not path then
    return nil
  end
  local p = M.project_at(path)
  if not p then
    return nil
  end
  local detail = { root = p.root, path = p.path, targets = p.targets }
  detail_cache[dkey] = detail
  return vim.tbl_extend('force', stub, detail)
end

local function stub_names(stubs)
  local names = {}
  for _, stub in ipairs(stubs) do
    names[#names + 1] = stub.name
  end
  return names
end

local function store_list(root, target, stubs)
  list_cache[mem_key(root, target)] = stubs
  local remote_id = workspace.git_remote_id(root)
  if remote_id then
    write_disk_cache(remote_id, target, nx_mtime(root), stub_names(stubs))
  end
end

function M.project_at(path)
  local data = workspace.read_json(path)
  if not data then
    return nil
  end
  return {
    name = data.name or vim.fn.fnamemodify(vim.fn.fnamemodify(path, ':h'), ':t'),
    root = vim.fn.fnamemodify(path, ':h'),
    path = path,
    targets = data.targets or {},
  }
end

--- Disk cache (stale ok), or empty — never blocks on nx CLI or glob scan.
function M.list(root, target)
  root = root or workspace.root()
  if not root then
    return {}
  end

  local key = mem_key(root, target)
  local mem = list_cache[key]
  if mem and #mem > 0 then
    return mem
  end

  local remote_id = workspace.git_remote_id(root)
  local mtime = nx_mtime(root)
  if remote_id then
    local cached = read_disk_cache(remote_id, target, mtime)
    if cached then
      list_cache[key] = cached
      return cached
    end
  end

  return {}
end

function M.inflight(root, target)
  local remote_id = workspace.git_remote_id(root)
  return inflight[cache_token(remote_id, target)] ~= nil
end

--- Async nx fetch; single-flight per remote+target. opts.on_done(stubs?, err?).
function M.refresh_list(root, target, opts)
  opts = opts or {}
  root = root or workspace.root()
  if not root then
    if opts.on_done then
      opts.on_done(nil, 'no nx.json')
    end
    return false
  end

  local remote_id = workspace.git_remote_id(root)
  local token = cache_token(remote_id, target)
  local pending = inflight[token]
  if pending then
    if opts.on_done then
      pending.waiters[#pending.waiters + 1] = opts.on_done
    end
    if opts.picker then
      pending.pickers[#pending.pickers + 1] = opts.picker
      if not opts.picker.closed then
        opts.picker.title = pending.status or 'Nx: loading project list…'
        opts.picker:update_titles()
      end
    end
    return false
  end

  inflight[token] = {
    waiters = opts.on_done and { opts.on_done } or {},
    pickers = opts.picker and { opts.picker } or {},
    status = 'Nx: loading project list…',
  }
  emit_status(token, inflight[token].status)

  local args = { 'show', 'projects', '--json' }
  if target then
    args[#args + 1] = '--with-target=' .. target
  end

  vim.system(workspace.nx_cmd(root, args), { cwd = root, text = true, env = vim.fn.environ() }, function(result)
    vim.schedule(function()
      local stubs, err
      if result.code == 0 and result.stdout and result.stdout ~= '' then
        local names = decode_project_names(result.stdout)
        if names then
          stubs = names_to_stubs(names)
          store_list(root, target, stubs)
        else
          err = 'failed to parse nx output'
        end
      else
        err = (result.stderr and vim.trim(result.stderr) ~= '') and vim.trim(result.stderr)
          or 'nx show projects failed'
        nx_unavailable[root] = true
        local names = fallback_project_names(root, target)
        if #names > 0 then
          stubs = names_to_stubs(names)
          store_list(root, target, stubs)
          err = err .. ' (saved glob fallback)'
        end
      end

      local job = inflight[token]
      inflight[token] = nil
      local waiters = job and job.waiters or {}

      if stubs and #stubs > 0 then
        local msg = ('Nx: %d projects loaded'):format(#stubs)
        if err then
          msg = msg .. ' — ' .. err
        end
        notify_status(msg, err and vim.log.levels.WARN or vim.log.levels.INFO)
        for _, picker in ipairs(job and job.pickers or {}) do
          if picker and not picker.closed then
            picker.title = msg
            picker:update_titles()
          end
        end
      else
        notify_status(err or 'Nx: no projects found', vim.log.levels.ERROR)
      end

      for _, cb in ipairs(waiters) do
        cb(stubs, err)
      end
    end)
  end)

  return true
end

--- Load targets/root for one project — project.json first; nx only when needed.
function M.hydrate(stub, root)
  if stub.targets and stub.root then
    return stub
  end

  root = root or workspace.root()
  if not root then
    return stub
  end

  local dkey = mem_key(root, nil) .. '\0' .. stub.name
  if detail_cache[dkey] then
    return vim.tbl_extend('force', stub, detail_cache[dkey])
  end

  local from_index = hydrate_from_index(stub, root, dkey)
  if from_index then
    return from_index
  end

  if not get_path_index(root) then
    scan_projects(root, nil)
    from_index = hydrate_from_index(stub, root, dkey)
    if from_index then
      return from_index
    end
  end

  if not nx_unavailable[root] then
    local result = run_nx(root, { 'show', 'project', stub.name, '--json' }, 8000)
    if result.code == 0 and result.stdout and result.stdout ~= '' then
      local ok, data = pcall(vim.fn.json_decode, result.stdout)
      if ok and type(data) == 'table' then
        local rel = data.root or data.sourceRoot or ''
        local detail = {
          root = rel ~= '' and (root .. '/' .. rel) or root,
          path = rel ~= '' and (root .. '/' .. rel .. '/project.json') or '',
          targets = data.targets or {},
        }
        detail_cache[dkey] = detail
        return vim.tbl_extend('force', stub, detail)
      end
    else
      nx_unavailable[root] = true
    end
  end

  return stub
end

--- Background index build so select does not pay for a cold glob on first pick.
function M.warm_path_index(root)
  root = root or workspace.root()
  if not root or get_path_index(root) then
    return
  end
  vim.schedule(function()
    if not get_path_index(root) then
      scan_projects(root, nil)
    end
  end)
end

function M.projects(root)
  local stubs = M.list(root)
  root = root or workspace.root()
  return vim.tbl_map(function(s)
    return M.hydrate(s, root)
  end, stubs)
end

function M.configurations(project, target)
  local configs = vim.tbl_get(project.targets, target, 'configurations')
  if type(configs) ~= 'table' then
    return {}
  end
  local names = vim.tbl_keys(configs)
  table.sort(names)
  return names
end

function M.projects_with_target(root, target)
  return M.list(root, target)
end

function M.targets_for_project(project)
  local out = {}
  for _, kind in ipairs(M.kinds) do
    if project.targets and project.targets[kind.target] then
      out[#out + 1] = kind
    end
  end
  return out
end

function M.projects_with_any_target(root)
  local stubs = M.list(root)
  root = root or workspace.root()
  local out = {}
  for _, stub in ipairs(stubs) do
    local p = M.hydrate(stub, root)
    if #M.targets_for_project(p) > 0 then
      out[#out + 1] = p
    end
  end
  return out
end

function M.playwright_projects(project_root)
  local config = project_root .. '/playwright.config.ts'
  if vim.fn.filereadable(config) ~= 1 then
    return {}
  end

  local mtime = vim.fn.getftime(config)
  local cached = pw_cache[config]
  if cached and cached.mtime == mtime then
    return cached.names
  end

  local ws = workspace.root() or project_root
  local pw_bin = ws .. '/node_modules/.bin/playwright'
  local cmd
  if vim.fn.executable(pw_bin) == 1 then
    cmd = { pw_bin, 'test', '--config=' .. config, '--list', '--reporter=json' }
  else
    cmd = { 'npx', 'playwright', 'test', '--config=' .. config, '--list', '--reporter=json' }
  end

  local result = vim.system(cmd, { cwd = project_root, text = true, env = vim.fn.environ() }):wait()
  if result.code ~= 0 or not result.stdout or result.stdout == '' then
    return cached and cached.names or {}
  end

  local ok, decoded = pcall(vim.fn.json_decode, result.stdout)
  if not ok or type(decoded) ~= 'table' then
    return cached and cached.names or {}
  end

  local names = {}
  local projects = vim.tbl_get(decoded, 'config', 'projects')
  if type(projects) == 'table' then
    for _, p in ipairs(projects) do
      if type(p) == 'table' and p.name then
        names[#names + 1] = p.name
      end
    end
  end
  table.sort(names)

  pw_cache[config] = { mtime = mtime, names = names }
  return names
end

function M.project_by_name(root, name)
  for _, stub in ipairs(M.list(root)) do
    if stub.name == name then
      return M.hydrate(stub, root)
    end
  end
  return nil
end

function M.invalidate()
  list_cache = {}
  detail_cache = {}
  path_index = {}
  nx_unavailable = {}
end

if os.getenv('NVIM_NX_DISCOVER_SELF_CHECK') == '1' then
  assert(workspace.normalize_remote('git@GitHub.com:Org/Repo.git') == 'git@github.com:Org/Repo')
  assert(workspace.normalize_remote('https://GitHub.com/Org/Repo.git') == 'https://github.com/org/repo')
  local stubs = names_to_stubs({ 'a', 'b' })
  assert(#stubs == 2 and stubs[1].name == 'a')
end

return M
