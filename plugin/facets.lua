if vim.g.vscode then
  return
end

local registry = require('facets.registry')
local lsp_apply = require('facets.lsp_apply')

local function facets_info(start)
  local ctx = type(start) == 'number' and registry.resolve_smart(start) or registry.resolve(start or 0)
  if not ctx then
    vim.notify('Facets: not in a git repository (no anchor)', vim.log.levels.WARN)
    return
  end

  local lines = {
    ('git root: %s'):format(ctx.root),
    '',
    'stacks:',
  }
  if #ctx.stacks == 0 then
    lines[#lines + 1] = '  (none)'
  else
    for _, s in ipairs(ctx.stacks) do
      lines[#lines + 1] = ('  %s  %s'):format(s.kind, s.path)
    end
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = 'active facets:'
  local active = registry.active(ctx)
  if #active == 0 then
    lines[#lines + 1] = '  (none)'
  else
    for _, entry in ipairs(active) do
      lines[#lines + 1] = '  ' .. entry.def.id
    end
  end

  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'Facets' })
end

vim.api.nvim_create_user_command('FacetsInfo', function(opts)
  local start = opts.bang and vim.loop.cwd() or 0
  facets_info(start)
end, { desc = 'Show git-root stacks and active project facets' })

local group = vim.api.nvim_create_augroup('kickstart_facets', { clear = true })

vim.api.nvim_create_autocmd({ 'DirChanged', 'VimEnter' }, {
  group = group,
  callback = function()
    registry.invalidate()
    lsp_apply.invalidate()
  end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  group = group,
  callback = function(args)
    lsp_apply.apply_for_buffer(args.buf)
    local ctx = registry.resolve(args.buf)
    registry.remember_ctx(ctx)
  end,
})
