local workspace = require('nx.workspace')

local M = {}

--- Extend this table to add more Nx target menus later.
M.kinds = {
  { target = 'e2e', label = 'E2E (Playwright)' },
  { target = 'test', label = 'Unit / integration test' },
}

local list_cache = {}
local detail_cache = {}
local pw_cache = {}

local function nx_mtime(root)
  return vim.fn.getftime(root .. '/nx.json')
end

local function cache_key(root, target)
  return root .. '\0' .. (target or '*') .. '\0' .. tostring(nx_mtime(root))
end

local function run_nx(root, args)
  local cmd = { 'npx', 'nx' }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { cwd = root, text = true, env = vim.fn.environ() }):wait()
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

  local ok, decoded = pcall(vim.fn.json_decode, result.stdout)
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

local function fallback_project_names(root, target)
  local names = {}
  for _, path in ipairs(scoped_project_paths(root)) do
    local data = workspace.read_json(path)
    if data and data.name then
      if not target or vim.tbl_get(data, 'targets', target) then
        names[#names + 1] = data.name
      end
    end
  end
  table.sort(names)
  return names
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

--- Lightweight stubs `{ name }` — call M.hydrate before reading targets/root.
function M.list(root, target)
  root = root or workspace.root()
  if not root then
    return {}
  end

  local key = cache_key(root, target)
  if list_cache[key] then
    return list_cache[key]
  end

  local names = nx_project_names(root, target) or fallback_project_names(root, target)
  local stubs = {}
  for _, name in ipairs(names) do
    stubs[#stubs + 1] = { name = name }
  end

  list_cache[key] = stubs
  return stubs
end

--- Load targets/root for one project (one nx daemon call).
function M.hydrate(stub, root)
  if stub.targets and stub.root then
    return stub
  end

  root = root or workspace.root()
  if not root then
    return stub
  end

  local dkey = cache_key(root, nil) .. '\0' .. stub.name
  if detail_cache[dkey] then
    return vim.tbl_extend('force', stub, detail_cache[dkey])
  end

  local result = run_nx(root, { 'show', 'project', stub.name, '--json' })
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
  end

  -- fallback: scan scoped paths for matching name
  for _, path in ipairs(scoped_project_paths(root)) do
    local p = M.project_at(path)
    if p and p.name == stub.name then
      detail_cache[dkey] = { root = p.root, path = p.path, targets = p.targets }
      return vim.tbl_extend('force', stub, detail_cache[dkey])
    end
  end

  return stub
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

--- Playwright browser/device projects; cached by playwright.config.ts mtime.
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
end

return M
