local workspace = require('nx.workspace')
local discover = require('nx.discover')

local M = {}

local graph_cache = {}

local function nx_mtime(root)
  return vim.fn.getftime(root .. '/nx.json')
end

local function run_nx(root, args)
  return vim.system(workspace.nx_cmd(root, args), { cwd = root, text = true, env = vim.fn.environ() }):wait()
end

local function graph_dependencies(data)
  if not data then
    return nil
  end
  return vim.tbl_get(data, 'graph', 'dependencies') or data.dependencies
end

local function load_graph(root)
  local mtime = nx_mtime(root)
  if graph_cache[root] and graph_cache[root].mtime == mtime then
    return graph_cache[root].dependencies
  end

  local tmp = vim.fn.tempname() .. '.json'
  local result = run_nx(root, { 'graph', '--file=' .. tmp })
  if result.code ~= 0 then
    return nil
  end

  local data = workspace.read_json(tmp)
  vim.fn.delete(tmp)

  local dependencies = graph_dependencies(data)
  if type(dependencies) ~= 'table' then
    return nil
  end

  graph_cache[root] = { mtime = mtime, dependencies = dependencies }
  return dependencies
end

local function reverse_index(dependencies)
  local reverse = {}
  for source, edges in pairs(dependencies) do
    if type(edges) == 'table' then
      for _, edge in ipairs(edges) do
        if type(edge) == 'table' and edge.target then
          reverse[edge.target] = reverse[edge.target] or {}
          reverse[edge.target][source] = true
        end
      end
    end
  end
  return reverse
end

--- Transitive dependents: projects that import `project_name` (directly or indirectly).
function M.dependents(root, project_name)
  root = root or workspace.root()
  if not root or not project_name then
    return {}
  end

  local dependencies = load_graph(root)
  if not dependencies then
    return {}
  end

  local reverse = reverse_index(dependencies)
  local names = {}
  local seen = {}
  local queue = {}

  for name in pairs(reverse[project_name] or {}) do
    queue[#queue + 1] = name
  end

  while #queue > 0 do
    local name = table.remove(queue, 1)
    if not seen[name] then
      seen[name] = true
      names[#names + 1] = name
      for next_name in pairs(reverse[name] or {}) do
        if not seen[next_name] then
          queue[#queue + 1] = next_name
        end
      end
    end
  end

  table.sort(names)

  local out = {}
  for _, name in ipairs(names) do
    local project = discover.project_by_name(root, name)
    if project and project.root then
      out[#out + 1] = { name = name, root = project.root }
    end
  end
  return out
end

function M.invalidate()
  graph_cache = {}
end

return M
