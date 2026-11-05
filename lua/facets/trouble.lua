local registry = require('facets.registry')
local trouble_jump = require('facets.trouble_jump')
local eslint_run = require('facets.eslint')
local tsc_run = require('facets.tsc')
local knip_run = require('facets.knip')

local M = {}

---@param opts { mode: string, source: string, desc: string, preview_title: string }
---@return trouble.Source
local function make_source(opts)
  local src = { items = {} }
  src.config = {
    modes = {
      [opts.mode] = {
        desc = opts.desc,
        source = opts.source,
        focus = true,
        follow = false,
        auto_preview = true,
        win = {
          type = 'split',
          position = 'bottom',
          height = 16,
        },
        -- Trouble draws border/title only on float previews, not splits.
        preview = {
          type = 'float',
          relative = 'win',
          border = 'rounded',
          title = opts.preview_title,
          title_pos = 'center',
          position = { 0, 1 },
          size = { width = 0.48, height = 0.92 },
          scratch = true,
          focusable = false,
        },
        groups = {
          { 'directory' },
          { 'filename', format = '{file_icon} {basename} {count}' },
        },
        sort = { 'severity', 'filename', 'pos', 'message' },
        format = '{severity_icon} {message} {code} {pos}',
        keys = trouble_jump.keys(),
      },
    },
  }
  function src.set_items(items)
    src.items = items or {}
  end
  function src.get(cb, _ctx)
    cb(src.items)
  end
  return src
end

local SPECS = {
  eslint = {
    facet_id = 'typescript.eslint',
    label = 'ESLint',
    clean_msg = 'no problems',
    mode = 'facet_eslint',
    source = 'facets_eslint',
    desc = 'ESLint project lint (npx eslint .)',
    preview_title = ' ESLint preview ',
    run = eslint_run.project_lint,
  },
  tsc = {
    facet_id = 'typescript.tsc',
    label = 'tsc',
    clean_msg = 'no errors',
    mode = 'facet_tsc',
    source = 'facets_tsc',
    desc = 'TypeScript project check (tsc --noEmit)',
    preview_title = ' tsc preview ',
    run = tsc_run.project_check,
  },
  knip = {
    facet_id = 'typescript.knip',
    label = 'Knip',
    clean_msg = 'no issues',
    mode = 'facet_knip',
    source = 'facets_knip',
    desc = 'Knip project report',
    preview_title = ' Knip preview ',
    run = knip_run.project_run,
  },
}

M.sources = {}
M.modes = {}
local RUNNERS = {}

for key, spec in pairs(SPECS) do
  local src = make_source(spec)
  M.sources[spec.source] = src
  M.modes[spec.mode] = src.config.modes[spec.mode]

  RUNNERS[key] = function(ctx, _opts)
    trouble_jump.capture_origin(ctx.root)
    spec.run(ctx, function(err, items)
      if err then
        vim.notify(spec.label .. ': ' .. err, vim.log.levels.ERROR)
        return
      end
      src.set_items(items or {})
      local count = #(items or {})
      require('trouble').open({
        mode = spec.mode,
        focus = true,
        title = count == 0 and (spec.label .. ' (project): clean') or ('%s (project): %d'):format(spec.label, count),
      })
      if count == 0 then
        vim.notify(spec.label .. ': ' .. spec.clean_msg, vim.log.levels.INFO)
      end
    end)
  end
end

M.run_eslint = RUNNERS.eslint
M.run_tsc = RUNNERS.tsc
M.run_knip = RUNNERS.knip

function M.register_sources()
  local sources = require('trouble.sources')
  for name, src in pairs(M.sources) do
    sources.register(name, src)
  end
end

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

local function open_for_facet(key, opts)
  local spec = SPECS[key]
  local ctx = resolve_ctx(opts)
  if not ctx or not registry.has_facet(spec.facet_id, ctx.root) then
    if ctx then
      vim.notify('Facets: ' .. spec.facet_id .. ' not active for this repo', vim.log.levels.WARN)
    end
    return
  end
  RUNNERS[key](ctx, opts)
end

function M.open_eslint(opts)
  open_for_facet('eslint', opts)
end

function M.open_tsc(opts)
  open_for_facet('tsc', opts)
end

return M
