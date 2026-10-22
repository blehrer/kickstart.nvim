local registry = require('facets.registry')
local eslint_run = require('facets.eslint.run')
local eslint_source = require('facets.eslint.trouble_source')

local M = {}

function M.open_eslint(opts)
  opts = opts or {}
  local ctx = registry.resolve_smart(opts.bufnr)
  if not ctx then
    vim.notify(
      'Facets: not in a git repository (open a project file, :cd to the repo, or :FacetsInfo)',
      vim.log.levels.WARN
    )
    return
  end
  local active = registry.active(ctx)
  local found
  for _, entry in ipairs(active) do
    if entry.def.id == 'typescript.eslint' then
      found = true
      break
    end
  end
  if not found then
    vim.notify('Facets: typescript.eslint not active for this repo', vim.log.levels.WARN)
    return
  end

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

return M
