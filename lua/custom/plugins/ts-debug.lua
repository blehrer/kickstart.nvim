-- ts-debug.lua
--

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'microsoft/vscode-js-debug',
    'mxsdev/nvim-dap-vscode-js',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local kickstart = require 'kickstart.plugins.debug'
    dapui.setup(kickstart.config())

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
      },
    }

    -- ts
    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'node',
        -- 💀 Make sure to update this path to point to your installation
        args = { '~/.local/share/nvim/lazy/vscode-js-debug/src/dapDebugServer.ts', '${port}' },
      },
    }

    require('dap-vscode-js').setup {
      node_path = 'deno', -- Path of node executable. Defaults to $NODE_PATH, and then "node"
      debugger_path = '(runtimedir)/lazy/vscode-js-debugger/src/dapDebugServer.ts', -- Path to vscode-js-debug installation.
      debugger_cmd = { 'js-debug-adapter' }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
      adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
      log_file_path = '~/.cache/nvim/dap_vscode_js.log', -- Path for file logging
      log_file_level = 0, -- Logging level for output to file. Set to false to disable file logging.
      log_console_level = vim.log.levels.ERROR, -- Logging level for output to console. Set to false to disable console output.
    }

    for _, language in ipairs { 'typescript', 'javascript', 'typescriptreact', 'jsx' } do
      dap = require 'dap'
      dap.configurations[language] = {
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
  end,
}
