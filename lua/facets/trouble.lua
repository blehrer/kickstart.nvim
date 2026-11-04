local registry = require('facets.registry')
local trouble_jump = require('facets.trouble_jump')
local eslint_run = require('facets.eslint.run')
local eslint_source = require('facets.eslint.trouble_source')
local tsc_run = require('facets.tsc.run')
local tsc_source = require('facets.tsc.trouble_source')
local knip_run = require('facets.knip.run')
local knip_source = require('facets.knip.trouble_source')

local M = {}

local RUNNERS = {}

function M.run_eslint(ctx, _opts)
  trouble_jump.capture_origin(ctx.root)
  eslint_run.project_lint(ctx, function(err, items)
    if err then
      vim.notify('ESLint: ' .. err, vim.log.levels.ERROR)
      return
    end
    eslint_source.set_items(items or {})
    local count = #(items or {})
    require('trouble').open({
      mode = 'facet_eslint',
      focus = true,
      title = count == 0 and 'ESLint (project): clean' or ('ESLint (project): %d'):format(count),
    })
    if count == 0 then
      vim.notify('ESLint: no problems', vim.log.levels.INFO)
    end
  end)
end

function M.run_tsc(ctx, _opts)
  trouble_jump.capture_origin(ctx.root)
  tsc_run.project_check(ctx, function(err, items)
    if err then
      vim.notify('tsc: ' .. err, vim.log.levels.ERROR)
      return
    end
    tsc_source.set_items(items or {})
    local count = #(items or {})
    require('trouble').open({
      mode = 'facet_tsc',
      focus = true,
      title = count == 0 and 'tsc (project): clean' or ('tsc (project): %d'):format(count),
    })
    if count == 0 then
      vim.notify('tsc: no errors', vim.log.levels.INFO)
    end
  end)
end

function M.run_knip(ctx, _opts)
  trouble_jump.capture_origin(ctx.root)
  knip_run.project_run(ctx, function(err, items)
    if err then
      vim.notify('Knip: ' .. err, vim.log.levels.ERROR)
      return
    end
    knip_source.set_items(items or {})
    local count = #(items or {})
    require('trouble').open({
      mode = 'facet_knip',
      focus = true,
      title = count == 0 and 'Knip (project): clean' or ('Knip (project): %d'):format(count),
    })
    if count == 0 then
      vim.notify('Knip: no issues', vim.log.levels.INFO)
    end
  end)
end

RUNNERS.eslint = M.run_eslint
RUNNERS.tsc = M.run_tsc
RUNNERS.knip = M.run_knip

local function resolve_ctx(opts)
  opts = opts or {}
  local ctx = registry.resolve_smart(opts.bufnr)
  if not ctx then
    vim.notify(
      'Facets: not in a git repository (open a project file, :cd to the repo, or :FacetsInfo)',
      vim.log.levels.WARN
    )
    return nil
  end
  return ctx
end

function M.run_runner(runner, ctx, opts)
  local fn = RUNNERS[runner]
  if not fn then
    vim.notify('Facets: unknown trouble runner ' .. tostring(runner), vim.log.levels.ERROR)
    return
  end
  fn(ctx, opts)
end

--- Snacks picker over active facets that register facet.trouble.
function M.pick(opts)
  local ctx = resolve_ctx(opts)
  if not ctx then
    return
  end

  local choices = registry.trouble_choices(ctx, RUNNERS)
  if #choices == 0 then
    vim.notify('Facets: no active facet checks for this repo (:FacetsInfo)', vim.log.levels.WARN)
    return
  end

  local Snacks = require('snacks')
  Snacks.picker.select(choices, {
    prompt = 'Active facet check:',
    format_item = function(choice)
      return ('%s  %s'):format(choice.label, choice.facet_id)
    end,
  }, function(choice)
    if choice then
      M.run_runner(choice.runner, ctx, opts)
    end
  end)
end

function M.open_eslint(opts)
  local ctx = resolve_ctx(opts)
  if not ctx or not registry.has_facet('typescript.eslint', ctx.root) then
    if ctx then
      vim.notify('Facets: typescript.eslint not active for this repo', vim.log.levels.WARN)
    end
    return
  end
  M.run_eslint(ctx, opts)
end

function M.open_tsc(opts)
  local ctx = resolve_ctx(opts)
  if not ctx or not registry.has_facet('typescript.tsc', ctx.root) then
    if ctx then
      vim.notify('Facets: typescript.tsc not active for this repo', vim.log.levels.WARN)
    end
    return
  end
  M.run_tsc(ctx, opts)
end

return M
