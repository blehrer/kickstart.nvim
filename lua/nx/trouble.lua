local discover = require('nx.discover')
local graph = require('nx.graph')
local workspace = require('nx.workspace')

local M = {}

local scopes = {}

local function normalize_root(root)
  root = vim.fn.fnamemodify(root, ':p')
  if root:sub(-1) ~= '/' then
    root = root .. '/'
  end
  return root
end

local function under_root(path, root)
  path = vim.fn.fnamemodify(path, ':p')
  return path:find(normalize_root(root), 1, true) == 1
end

local function under_any_root(path, roots)
  for _, root in ipairs(roots) do
    if under_root(path, root) then
      return true
    end
  end
  return false
end

function M.current_project()
  local pj = workspace.nearest_project_json()
  if not pj then
    return nil
  end

  local ws = workspace.root(vim.fn.fnamemodify(pj, ':h'))
  if not ws then
    return nil
  end

  local stub = discover.project_at(pj)
  if not stub then
    return nil
  end

  return discover.hydrate(stub, ws), ws
end

function M.roots_for_buffer(opts)
  opts = opts or {}
  local project, ws = M.current_project()
  if not project then
    return nil
  end

  local roots = { project.root }
  if opts.include_dependents then
    for _, dependent in ipairs(graph.dependents(ws, project.name)) do
      roots[#roots + 1] = dependent.root
    end
  end
  return roots, project
end

function M.make_filter(mode)
  return function(items)
    local roots = scopes[mode] or {}
    return vim.tbl_filter(function(item)
      return under_any_root(item.filename, roots)
    end, items)
  end
end

function M.open(opts)
  opts = opts or {}
  local mode = opts.include_dependents and 'nx_diagnostics_dependents' or 'nx_diagnostics'
  local roots, project = M.roots_for_buffer(opts)
  if not roots then
    vim.notify('No Nx project for current buffer', vim.log.levels.WARN)
    return
  end

  scopes[mode] = roots
  require('trouble').toggle({
    mode = mode,
    title = opts.include_dependents
        and ('Nx diagnostics: %s + dependents'):format(project.name)
        or ('Nx diagnostics: %s'):format(project.name),
  })
end

return M
