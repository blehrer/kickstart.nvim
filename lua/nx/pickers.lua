local discover = require('nx.discover')
local workspace = require('nx.workspace')

local M = {}

local REFRESH_HINT = '<C-r> refresh'

local function list_height(count)
  return math.max(math.min(count, math.floor(vim.o.lines * 0.8 - 10)), 2)
end

--- Match snacks picker select sizing; walk nested layout boxes.
local function set_list_heights(layout, count)
  local h = list_height(count)
  local function walk(node)
    if type(node) ~= 'table' then
      return
    end
    if node.win == 'list' then
      node.height = h
    end
    for _, child in ipairs(node) do
      walk(child)
    end
  end
  walk(layout.layout)
end

local function layout_for_items(items)
  return {
    config = function(layout)
      set_list_heights(layout, #items)
      return layout
    end,
  }
end

local function sync_list_layout(picker, items)
  if not picker or picker.closed then
    return
  end
  picker.opts.layout = vim.tbl_extend('force', picker.opts.layout or {}, layout_for_items(items))
  picker:set_layout()
end

local function replace_items(items, stubs)
  for i = #items, 1, -1 do
    items[i] = nil
  end
  for i, stub in ipairs(stubs) do
    items[i] = stub
  end
end

local function title_for(count, loading)
  if loading then
    return 'Nx sub-project (loading… · ' .. REFRESH_HINT .. ')'
  end
  if count == 0 then
    return 'Nx sub-project (none cached · ' .. REFRESH_HINT .. ')'
  end
  return ('Nx sub-project (%d · %s)'):format(count, REFRESH_HINT)
end

local function apply_to_picker(picker, items, stubs, opts)
  stubs = stubs or {}
  if opts.prefer_current then
    stubs = workspace.bump_project_first(stubs)
  end
  replace_items(items, stubs)
  if picker and not picker.closed then
    picker.title = title_for(#stubs, false)
    picker:update_titles()
    sync_list_layout(picker, items)
    picker:refresh()
  end
end

local function attach_refresh(picker, root, target, items, opts)
  discover.refresh_list(root, target, {
    picker = picker,
    on_done = function(stubs, err)
      if stubs and #stubs > 0 then
        apply_to_picker(picker, items, stubs, opts)
      elseif err then
        vim.notify(err, vim.log.levels.ERROR, { id = 'nx-project-list', title = 'Nx' })
      end
    end,
  })
end

function M.pick_project(root, target, on_choice, projects, opts)
  opts = vim.tbl_extend('force', { prefer_current = false, auto_refresh = true }, opts or {})

  projects = projects
    or (target and discover.projects_with_target(root, target) or discover.list(root))
  if opts.prefer_current then
    projects = workspace.bump_project_first(projects)
  end

  local items = vim.deepcopy(projects)
  local loading = discover.inflight(root, target) or (#items == 0 and opts.auto_refresh)
  local prompt = title_for(#items, loading)

  -- Snacks closes source=select pickers with 0 rows unless show_empty is set;
  -- that runs before on_show, so refresh never started when the list was empty.
  local snacks_opts = {
    show_empty = true,
    title = prompt,
    layout = layout_for_items(items),
    on_show = function(picker)
      sync_list_layout(picker, items)
      if not opts.auto_refresh then
        return
      end
      if #items == 0 or discover.inflight(root, target) then
        picker.title = title_for(#items, true)
        picker:update_titles()
      end
      attach_refresh(picker, root, target, items, opts)
    end,
    actions = {
      nx_refresh = function(picker)
        picker.title = title_for(#items, true)
        picker:update_titles()
        attach_refresh(picker, root, target, items, opts)
      end,
    },
    win = {
      input = {
        keys = {
          ['<C-r>'] = { 'nx_refresh', mode = { 'n', 'i' } },
        },
      },
    },
  }

  if opts.auto_refresh and #items == 0 then
    attach_refresh(nil, root, target, items, opts)
  end

  Snacks.picker.select(items, {
    prompt = prompt,
    format_item = function(p)
      return p.name
    end,
    snacks = snacks_opts,
  }, function(stub)
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
  Snacks.picker.select(targets, {
    prompt = project.name .. ' target:',
    format_item = function(k)
      return k.label
    end,
  }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

function M.pick_playwright_project(project_root, on_choice)
  local names = discover.playwright_projects(project_root)
  if #names == 0 then
    return on_choice(nil)
  end
  local picker_items = { '(all Playwright projects)' }
  vim.list_extend(picker_items, names)
  Snacks.picker.select(picker_items, { prompt = 'Playwright sub-project:' }, function(choice)
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
  Snacks.picker.select(configs, { prompt = project.name .. ' env:' }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

function M.pick_debug(on_choice)
  Snacks.picker.select({ 'no', 'yes' }, { prompt = 'Debug node (NODE_OPTIONS=--inspect-brk):' }, function(choice)
    if choice then
      on_choice(choice == 'yes')
    end
  end)
end

function M.hydrate_by_name(root, name)
  return discover.hydrate({ name = name }, root)
end

return M
