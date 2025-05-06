require 'lazy.types'

---@type LazyPluginSpec[]
return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      {
        'rcarriga/nvim-dap-ui',
        dependencies = {
          'mfussenegger/nvim-dap',
          'nvim-neotest/nvim-nio',
          'folke/lazydev.nvim',
        },
        'williamboman/mason.nvim',
        'jay-babu/mason-nvim-dap.nvim',

        -- dap adapters:
        'mfussenegger/nvim-dap-python',
      },
    },
    config = function(self, opts)
      local dap, dapui = require 'dap', require 'dapui'
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

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
          'js-debug-adapter',
        },
      }
      require('dap-python').setup 'python3'

      local js_debug_dap_server = os.getenv 'HOME' .. '/.local/share/microsoft/js-debug/src/dapDebugServer.js'
      require('dap').adapters['pwa-node'] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = {
          command = 'node',
          args = { js_debug_dap_server, '${port}' },
        },
      }
      require('dap').configurations.typescript = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Debug Playwright Tests',
          -- trace = true, -- include debugger info
          runtimeExecutable = 'npx',
          runtimeArgs = {
            'playwright',
            'test',
            '--debug',
          },
          rootPath = '${workspaceFolder}',
          cwd = '${workspaceFolder}',
        },
      }
    end,
    keys = {
      -- Basic debugging keymaps, feel free to change to your liking!
      {
        '<F5>',
        function()
          require('dap').continue()
        end,
        desc = 'Debug: Start/Continue',
      },
      {
        '<F1>',
        function()
          require('dap').step_into()
        end,
        desc = 'Debug: Step Into',
      },
      {
        '<F2>',
        function()
          require('dap').step_over()
        end,
        desc = 'Debug: Step Over',
      },
      {
        '<F3>',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: Step Out',
      },
      {
        '<leader>b',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Debug: Toggle Breakpoint',
      },
      {
        '<leader>B',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Set Breakpoint',
      },
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      {
        '<F7>',
        function()
          require('dapui').toggle()
        end,
        desc = 'Debug: See last session result.',
      },
    },
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',

      -- Adapters
      {
        'thenbe/neotest-playwright',
        dependencies = 'nvim-telescope/telescope.nvim',
        keys = {
          {
            '<leader>ta',
            function()
              require('neotest').playwright.attachment()
            end,
            desc = 'Launch test attachment',
          },
        },
      },
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require('neotest-playwright').adapter {
            options = {
              persist_project_selection = true,
              enable_dynamic_test_discovery = true,
            },
          },
        },

        consumers = {
          playwright = require('neotest-playwright.consumers').consumers,
        },
      }
    end,
  },
  {
    'mxsdev/nvim-dap-vscode-js',
    dependencies = {
      'thenbe/neotest-playwright',
      'nvim-neotest/neotest',
    },
    opts = function()
      local js_debug_dap_server = os.getenv 'HOME' .. '/.local/share/microsoft/js-debug/src/dapDebugServer.js'
      require('dap').adapters['pwa-node'] = {
        type = 'server',
        host = 'localhost',
        port = 8123,
        executable = {
          command = 'node',
          args = { js_debug_dap_server, 8123 },
        },
      }
      require('dap').configurations.typescript = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Debug Playwright Tests',
          -- trace = true, -- include debugger info
          runtimeExecutable = 'npx',
          runtimeArgs = {
            'playwright',
            'test',
            '--debug',
          },
          rootPath = '${workspaceFolder}',
          cwd = '${workspaceFolder}',
        },
      }
      require('neotest').setup {
        adapters = {
          require('neotest-playwright').adapter {
            options = {
              persist_project_selection = true,
              enable_dynamic_test_discovery = true,
            },
          },
        },
        consumers = {
          -- add to your list of consumers
          playwright = require('neotest-playwright.consumers').consumers,
        },
      }
      local dapui = require 'dapui'
      dapui.setup {}
      return {
        debugger_cmd = { 'node', js_debug_dap_server, 8123 },
        adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost', 'python' }, -- which adapters to register in nvim-dap
        -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
        -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
        -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
      }
    end,
    keys = {
      {
        '<leader>dc',
        function()
          vim.api.nvim_command 'Telescope dap commands'
        end,
        desc = '[DAP]: [C]ommands',
      },
    },
  },
}
