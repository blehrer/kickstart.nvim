local anchor = require('facets.anchor')

local M = {}

M.id = 'go.mod'
M.requires = { 'go' }

function M.detect(_ctx)
  return true
end

function M.lsp(_ctx)
  return { enable = { 'gopls' } }
end

function M.dap(ctx)
  local root = (ctx and ctx.root) or vim.loop.cwd()
  local dlv = anchor.mason_bin('dlv')
  local adapter = function(callback, config)
    if config.mode == 'remote' and config.request == 'attach' then
      callback({
        type = 'server',
        host = config.host or '127.0.0.1',
        port = config.port or '38697',
      })
      return
    end
    callback({
      type = 'server',
      port = '${port}',
      executable = {
        command = dlv,
        args = { 'dap', '-l', '127.0.0.1:${port}', '--log', '--log-output=dap' },
        detached = vim.fn.has('win32') == 0,
      },
    })
  end

  return {
    adapters = {
      delve = adapter,
      go = adapter,
    },
    configurations = {
      go = {
        {
          type = 'delve',
          name = 'Go: Debug file / package',
          request = 'launch',
          program = '${file}',
          cwd = root,
        },
        {
          type = 'delve',
          name = 'Go: Debug test (current package)',
          request = 'launch',
          mode = 'test',
          program = './${relativeFileDirname}',
          cwd = root,
        },
        {
          type = 'delve',
          name = 'Go: Attach local process (PID)',
          mode = 'local',
          request = 'attach',
          processId = function()
            return require('dap.utils').pick_process()
          end,
        },
      },
    },
  }
end

return M
