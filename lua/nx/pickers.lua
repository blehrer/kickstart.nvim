local discover = require('nx.discover')
local workspace = require('nx.workspace')

local M = {}

local function select(items, prompt, format_item, on_choice)
  Snacks.picker.select(items, {
    prompt = prompt,
    format_item = format_item,
  }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

function M.pick_project(root, target, on_choice, projects)
  projects = projects
    or (target and discover.projects_with_target(root, target) or discover.list(root))
  if #projects == 0 then
    vim.notify('No Nx projects found', vim.log.levels.WARN)
    return
  end
  select(projects, 'Nx sub-project:', function(p)
    return p.name
  end, function(stub)
    if stub then
      on_choice(discover.hydrate(stub, root))
    end
  end)
end

function M.pick_target(project, on_choice)
  local targets = discover.targets_for_project(project)
  if #targets == 0 then
    vim.notify('No runnable targets on ' .. project.name, vim.log.levels.WARN)
    return
  end
  if #targets == 1 then
    return on_choice(targets[1])
  end
  select(targets, project.name .. ' target:', function(k)
    return k.label
  end, on_choice)
end

function M.pick_playwright_project(project_root, on_choice)
  local names = discover.playwright_projects(project_root)
  if #names == 0 then
    return on_choice(nil)
  end
  local items = { '(all Playwright projects)' }
  vim.list_extend(items, names)
  select(items, 'Playwright sub-project:', nil, function(choice)
    if not choice or choice == '(all Playwright projects)' then
      on_choice(nil)
    else
      on_choice(choice)
    end
  end)
end

function M.pick_env(project, target, on_choice)
  local configs = discover.configurations(project, target)
  if #configs == 0 then
    return on_choice(nil)
  end
  select(configs, project.name .. ' env:', nil, on_choice)
end

function M.pick_debug(on_choice)
  select({ 'no', 'yes' }, 'Debug node (NODE_OPTIONS=--inspect-brk):', nil, function(choice)
    if choice then
      on_choice(choice == 'yes')
    end
  end)
end

function M.hydrate_by_name(root, name)
  return discover.hydrate({ name = name }, root)
end

return M
