require 'lazy.types'
---@type LazyPluginSpec[]
return {

  -- {{{DAP config
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      { 'igorlfs/nvim-dap-view', opts = {} },
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
        {
          'jbyuki/one-small-step-for-vimkind',
          config = function()
            local dap = require 'dap'
            dap.adapters.nlua = function(callback, conf)
              local adapter = {
                type = 'server',
                host = conf.host or '127.0.0.1',
                port = conf.port or 8086,
              }
              if conf.start_neovim then
                local dap_run = dap.run
                dap.run = function(c)
                  adapter.port = c.port
                  adapter.host = c.host
                end
                require('osv').run_this()
                dap.run = dap_run
              end
              callback(adapter)
            end
            dap.configurations.lua = {
              {
                type = 'nlua',
                request = 'attach',
                name = 'Run this file',
                start_neovim = {},
              },
              {
                type = 'nlua',
                request = 'attach',
                name = 'Attach to running Neovim instance (port = 8086)',
                port = 8086,
              },
            }
          end,
        },

        -- dap ui stuff:
        'theHamsta/nvim-dap-virtual-text',
        'grapp-dev/nui-components.nvim',
        {
          'carcuis/dap-breakpoints.nvim',
          -- 'blehrer/dap-breakpoints.nvim',
          -- branch = 'multiprop-breakpoint-editing'
          -- dir = vim.fs.joinpath(os.getenv 'WORKSPACE', 'blehrer', 'dap-breakpoints.nvim'),
          opts = {
            virtual_text = { enabled = false },
          },
          dependencies = {
            'Weissle/persistent-breakpoints.nvim',
            opts = {},
          },
        },
      },
    },
    config = function(self, opts)
      local dap, dapui = require 'dap', require 'dap-view'
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
      vim.cmd 'hi DapBreakpointColor guifg=#fa4848'
      vim.fn.sign_define('DapBreakpoint', { text = '⦿', texthl = 'DapBreakpointColor', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '⨕', texthl = 'DapBreakpointColor', linehl = '', numhl = '' })

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
      require('nvim-dap-virtual-text').setup {}

      require('dap-python').setup 'python'

      dap.adapters.nlua = function(callback, conf)
        local adapter = {
          type = 'server',
          host = conf.host or '127.0.0.1',
          port = conf.port or 8086,
        }
        if conf.start_neovim then
          local dap_run = dap.run
          dap.run = function(c)
            adapter.port = c.port
            adapter.host = c.host
          end
          require('osv').run_this()
          dap.run = dap_run
        end
        callback(adapter)
      end

      local js_debug_dap_server = os.getenv 'HOME' .. '/.local/share/microsoft/js-debug/src/dapDebugServer.js'
      dap.adapters['pwa-node'] = {
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
          name = ('%s Launch file'):format(require('mini.icons').get('filetype', 'typescript')),
          program = '${file}',
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = ('%s Attach'):format(require('mini.icons').get('filetype', 'typescript')),
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = ('%s Debug Playwright Tests'):format(require('mini.icons').get('filetype', 'typescript')),
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
        desc = '[D]ebug: Start/Continue',
      },
      {
        '<F1>',
        function()
          require('dap').step_into()
        end,
        desc = '[D]ebug: Step Into',
      },
      {
        '<F2>',
        function()
          require('dap').step_over()
        end,
        desc = '[D]ebug: Step Over',
      },
      {
        '<F3>',
        function()
          require('dap').step_out()
        end,
        desc = '[D]ebug: Step Out',
      },
      {
        '<leader>b',
        function()
          require('dap-breakpoints.api').toggle_breakpoint()
          -- require('dap').toggle_breakpoint()
          -- vim.api.nvim__redraw {
          --   statusline = true,
          -- }
        end,
        desc = 'Toggle [b]reakpoint',
      },
      {
        '<leader>be',
        function()
          require('dap-breakpoints.api').edit_property { all = true }
        end,
        -- edit_breakpoint,
        desc = '[b]reakpoint [e]ditor',
        mode = 'n',
      },
      {
        '<leader>B',
        function()
          require('dap-breakpoints.api').edit_property { all = true }
        end,
        desc = 'Edit [B]reakpoint',
        mode = 'n',
      },
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      {
        '<F7>',
        function()
          require('dap-view').toggle(true)
        end,
        desc = '[D]ebug: See last session result.',
      },
      {
        '<leader>dh',
        function()
          require('nvim-dap-virtual-text').toggle()
        end,
        desc = '[D]ebug: toggle virtual text [h]ints',
      },
      {
        '<leader>dc',
        function()
          vim.api.nvim_command 'Telescope dap commands'
        end,
        desc = '[D]ebug: [C]ommands',
      },
      {
        '<leader>df',
        function()
          local widgets = require 'dap.ui.widgets'
          widgets.centered_float(widgets.frames)
        end,
        desc = '[D]ebug: floating [f]rames widget',
      },
    },
  },
  -- }}}

  -- {{{NeoTest
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
  -- }}}

  -- {{{ nvim-dap-vscode-js
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
      local dapui = require 'dap-view'
      return {
        debugger_cmd = { 'node', js_debug_dap_server, 8123 },
        adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost', 'python' }, -- which adapters to register in nvim-dap
        -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
        -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
        -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
      }
    end,
  },
  ---}}}
}
--- vim: ts=2 sts=2 sw=2 et foldmethod=marker
