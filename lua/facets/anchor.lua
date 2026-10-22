local M = {}

local MANIFESTS = {
  { kind = 'node', paths = { 'package.json' } },
  { kind = 'gradle', paths = { 'build.gradle.kts', 'build.gradle' } },
  { kind = 'python', paths = { 'pyproject.toml' } },
  { kind = 'go', paths = { 'go.mod' } },
  { kind = 'rust', paths = { 'Cargo.toml' } },
}

local function git_toplevel_dir(dir)
  dir = vim.fn.fnamemodify(dir, ':p')
  if vim.fn.isdirectory(dir) ~= 1 then
    dir = vim.fn.fnamemodify(dir, ':h')
  end
  local result = vim.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout)
end

local function real_file_path(path)
  if not path or path == '' then
    return nil
  end
  if path:find('^%a[%w%-]*://') then
    return nil
  end
  return path
end

---@param start string|number|nil buffer, path, or bufnr
---@return string[]
local function dir_candidates(start)
  local seen = {}
  local out = {}
  local function add(raw)
    if not raw or raw == '' then
      return
    end
    local dir = raw
    if vim.fn.isdirectory(dir) ~= 1 then
      dir = vim.fn.fnamemodify(dir, ':p:h')
    else
      dir = vim.fn.fnamemodify(dir, ':p'):gsub('/$', '')
    end
    if dir == '' or seen[dir] then
      return
    end
    seen[dir] = true
    out[#out + 1] = dir
  end

  if type(start) == 'number' then
    add(real_file_path(vim.api.nvim_buf_get_name(start)))
  elseif type(start) == 'string' then
    add(real_file_path(start))
    if vim.fn.isdirectory(start) == 1 then
      add(start)
    end
  end

  add(vim.loop.cwd())
  return out
end

---@param start string|number|nil buffer path, directory, or nil for cwd
---@return string|nil
function M.git_toplevel(start)
  for _, dir in ipairs(dir_candidates(start)) do
    local root = git_toplevel_dir(dir)
    if root then
      return root
    end
    local fs_root = vim.fs.root(dir, { '.git' })
    if fs_root then
      root = git_toplevel_dir(fs_root)
      if root then
        return root
      end
    end
  end
  return nil
end

---@param root string
---@return table[]
function M.stacks_at(root)
  root = vim.fn.fnamemodify(root, ':p'):gsub('/$', '')
  local stacks = {}
  for _, spec in ipairs(MANIFESTS) do
    for _, name in ipairs(spec.paths) do
      local path = root .. '/' .. name
      if vim.fn.filereadable(path) == 1 then
        stacks[#stacks + 1] = {
          kind = spec.kind,
          path = path,
          mtime = vim.fn.getftime(path),
        }
        break
      end
    end
  end
  return stacks
end

local function stack_kinds(stacks)
  local kinds = {}
  for _, s in ipairs(stacks) do
    kinds[s.kind] = true
  end
  return kinds
end

local function cache_fingerprint(stacks)
  local parts = {}
  for _, s in ipairs(stacks) do
    parts[#parts + 1] = s.kind .. ':' .. tostring(s.mtime)
  end
  table.sort(parts)
  return table.concat(parts, '|')
end

---@param start string|number|nil
---@return table|nil ctx
function M.resolve(start)
  local root = M.git_toplevel(start)
  if not root then
    return nil
  end
  root = vim.fn.fnamemodify(root, ':p'):gsub('/$', '')
  local stacks = M.stacks_at(root)
  local workspace = require('nx.workspace')
  return {
    root = root,
    stacks = stacks,
    stack_kinds = stack_kinds(stacks),
    git_remote_id = workspace.git_remote_id(root),
    cache_key = (workspace.git_remote_id(root) or root) .. '\0' .. cache_fingerprint(stacks),
  }
end

return M
