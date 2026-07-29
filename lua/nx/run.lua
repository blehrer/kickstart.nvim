local M = {}

--- Build `npx nx run project:target:configuration -- extra`.
function M.compose(project, target, configuration, extra)
  local spec = project .. ':' .. target
  if configuration and configuration ~= '' then
    spec = spec .. ':' .. configuration
  end
  local cmd = { 'npx', 'nx', 'run', spec }
  if extra and extra ~= '' then
    cmd[#cmd + 1] = '--'
    for part in extra:gmatch('%S+') do
      cmd[#cmd + 1] = part
    end
  end
  return cmd
end

function M.compose_string(project, target, configuration, extra)
  local parts = M.compose(project, target, configuration, extra)
  return table.concat(parts, ' ')
end

function M.open_terminal(cmd, opts)
  opts = opts or {}
  if type(cmd) == 'string' then
    cmd = vim.split(cmd, '%s+')
  end

  if opts.debug_node then
    Snacks.terminal.open(cmd, {
      env = vim.tbl_extend('force', vim.fn.environ(), {
        NODE_OPTIONS = '--inspect-brk',
      }),
      cwd = opts.cwd,
      start_insert = true,
      auto_close = false,
    })
    vim.notify('Node inspector enabled — attach DAP (pwa-node) to port 9229 if needed', vim.log.levels.INFO)
    return
  end

  Snacks.terminal.open(cmd, {
    cwd = opts.cwd,
    start_insert = true,
    auto_close = false,
  })
end

return M
