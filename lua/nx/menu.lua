local discover = require('nx.discover')
local execute = require('nx.execute')
local workspace = require('nx.workspace')
local session_mod = require('nx.session')
local review = require('nx.review')
local pickers = require('nx.pickers')

local M = {}

local function bump_current_project(projects)
  local pj = workspace.nearest_project_json()
  if not pj then
    return projects
  end
  local data = workspace.read_json(pj)
  local current_name = data and data.name
  if not current_name then
    return projects
  end
  local ordered = {}
  for _, p in ipairs(projects) do
    if p.name == current_name then
      ordered[#ordered + 1] = p
    end
  end
  for _, p in ipairs(projects) do
    if p.name ~= current_name then
      ordered[#ordered + 1] = p
    end
  end
  return ordered
end

local function show_review(session)
  review.review(session, function(should_run, s)
    if not should_run then
      return
    end
    execute.execute(s)
  end)
end

local function continue(session, project, target)
  session:set_nx_project(project):set_target(target)

  local function done()
    show_review(session)
  end

  if target == 'e2e' then
    pickers.pick_playwright_project(project.root, function(pw_project)
      session:set_pw_project(pw_project)
      pickers.pick_env(project, target, function(env)
        session:set_env(env)
        done()
      end)
    end)
  else
    pickers.pick_env(project, target, function(env)
      session:set_env(env)
      done()
    end)
  end
end

--- Interactive Nx run: sub-project → PW project → env → review → run.
function M.run(opts)
  opts = opts or {}
  local root = workspace.root()
  if not root then
    vim.notify('No nx.json found above cwd', vim.log.levels.ERROR)
    return
  end

  local session = session_mod.new(root)

  local projects
  if opts.target then
    projects = discover.projects_with_target(root, opts.target)
  else
    projects = discover.list(root)
  end

  if opts.prefer_current_project then
    projects = bump_current_project(projects)
  end

  local function on_project(project)
    if not project then
      return
    end
    if opts.target then
      continue(session, project, opts.target)
      return
    end
    pickers.pick_target(project, function(kind)
      if not kind then
        return
      end
      continue(session, project, kind.target)
    end)
  end

  pickers.pick_project(root, opts.target, on_project, projects)
end

return M
