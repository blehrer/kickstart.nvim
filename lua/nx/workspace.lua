local M = {}

function M.root(start)
  local dir = start or vim.loop.cwd()
  if vim.fn.isdirectory(dir) ~= 1 then
    dir = vim.fn.fnamemodify(dir, ':h')
  end
  while dir ~= '/' and dir ~= '' do
    if vim.fn.filereadable(dir .. '/nx.json') == 1 then
      return dir
    end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

function M.read_json(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), '\n'))
  if not ok or type(decoded) ~= 'table' then
    return nil
  end
  return decoded
end

function M.nearest_project_json(start)
  start = start or vim.api.nvim_buf_get_name(0)
  if start == '' or vim.fn.isdirectory(start) == 1 then
    start = vim.loop.cwd()
  end
  local path = vim.fn.findfile('project.json', vim.fn.fnamemodify(start, ':p') .. ';')
  return path ~= '' and path or nil
end

--- Move the nx project for the current buffer to the front of a stub list.
function M.bump_project_first(stubs)
  local pj = M.nearest_project_json()
  if not pj then
    return stubs
  end
  local data = M.read_json(pj)
  local current_name = data and data.name
  if not current_name then
    return stubs
  end
  local ordered = {}
  for _, stub in ipairs(stubs) do
    if stub.name == current_name then
      ordered[#ordered + 1] = stub
    end
  end
  for _, stub in ipairs(stubs) do
    if stub.name ~= current_name then
      ordered[#ordered + 1] = stub
    end
  end
  return ordered
end

local remote_id_cache = {}

local function git_cmd(root, ...)
  local cmd = vim.list_extend({ 'git', '-C', root }, { ... })
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.trim(out)
end

local function terminal_remote(url)
  return url:match('^git@')
    or url:match('^ssh://')
    or url:match('^https?://')
end

--- Lowercase host; strip trailing .git for stable cache keys.
function M.normalize_remote(url)
  url = vim.trim(url or '')
  if url == '' then
    return url
  end
  url = url:gsub('%.git$', '')
  local host, path = url:match('^git@([^:]+):(.+)$')
  if host then
    return 'git@' .. host:lower() .. ':' .. path
  end
  local scheme, rest = url:match('^(https?://)(.+)$')
  if scheme then
    return scheme .. rest:lower()
  end
  return url
end

--- Follow relative/file remotes until we reach ssh or http(s).
local function resolve_remote(root, url, depth)
  depth = depth or 0
  if depth > 6 or not url or url == '' then
    return nil
  end
  if terminal_remote(url) then
    return M.normalize_remote(url)
  end

  local path
  if url:match('^file://') then
    path = url:gsub('^file://', '')
  elseif url:match('^/') then
    path = url
  elseif url:match('^%.') then
    path = vim.fn.fnamemodify(root .. '/' .. url, ':p')
  else
    return M.normalize_remote(url)
  end

  local toplevel = git_cmd(path, 'rev-parse', '--show-toplevel')
  if not toplevel then
    return nil
  end
  local next_url = git_cmd(toplevel, 'ls-remote', '--get-url', 'origin')
    or git_cmd(toplevel, 'remote', 'get-url', 'origin')
  if not next_url or next_url == url then
    return nil
  end
  return resolve_remote(toplevel, next_url, depth + 1)
end

--- Canonical git remote for disk cache dedup across local checkouts.
function M.git_remote_id(root)
  root = root or M.root()
  if not root then
    return nil
  end

  local norm = vim.fn.fnamemodify(root, ':p'):gsub('/$', '')
  if remote_id_cache[norm] then
    return remote_id_cache[norm]
  end

  local id
  if git_cmd(root, 'rev-parse', '--git-dir') == nil then
    id = norm .. '/'
  else
    local url = git_cmd(root, 'ls-remote', '--get-url', 'origin')
      or git_cmd(root, 'remote', 'get-url', 'origin')
    if not url or url == '' then
      local names = git_cmd(root, 'remote')
      if names and names ~= '' then
        url = git_cmd(root, 'remote', 'get-url', vim.split(names, '\n')[1])
      end
    end

    if not url or url == '' then
      id = norm .. '/'
    else
      id = resolve_remote(root, url) or M.normalize_remote(url)
    end
  end

  remote_id_cache[norm] = id
  return id
end

function M.nx_cmd(root, args)
  local bin = root .. '/node_modules/.bin/nx'
  local cmd = vim.fn.executable(bin) == 1 and { bin } or { 'npx', 'nx' }
  return vim.list_extend(cmd, args)
end

return M
