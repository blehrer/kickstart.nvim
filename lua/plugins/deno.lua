require 'lazy.types'
---@type LazyPluginSpec
return {
  'sigmasd/deno-nvim',
  event = 'VeryLazy',
  dependencies = {
    'mfussenegger/nvim-dap',
  },
  opts = function(_, _)
    local dap = require 'dap'

    local debug_server = os.getenv 'HOME' .. '/.local/share/microsoft/js-debug/src/dapDebugServer.js'
    local supported_filetypes = { 'typescript', 'typescriptreact', 'javascript' }

    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'node',
        args = {
          debug_server,
          '${port}',
        },
      },
    }

    for _, ft in ipairs(supported_filetypes) do
      dap.configurations[ft] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          runtimeExecutable = 'deno',
          runtimeArgs = {
            'run',
            '--inspect-wait',
            '--allow-all',
          },
          program = '${file}',
          cwd = '${workspaceFolder}',
          attachSimplePort = 9229,
        },
      }
    end
    vim.g.markdown_fenced_languages = {
      'ts=typescript',
    }
    return {
      dap = {
        server = {
          -- on_attach = ...,
          -- capabilities = ...,
          settings = {
            deno = {
              inlayHints = {
                parameterNames = {
                  enabled = 'all',
                },
                parameterTypes = {
                  enabled = true,
                },
                variableTypes = {
                  enabled = true,
                },
                propertyDeclarationTypes = {
                  enabled = true,
                },
                functionLikeReturnTypes = {
                  enabled = true,
                },
                enumMemberValues = {
                  enabled = true,
                },
              },
            },
          },
        },
        adapter = {
          executable = {
            args = { debug_server, '${port}' },
          },
        },
      },
    }
  end,
}
