---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- {{{Package management
    {
      'jay-babu/mason-nvim-dap.nvim',
      dependencies = { 'mason-org/mason.nvim' },
      lazy = false,
      priority = 49,
      opts = {
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
          'javadbg',
          'javatest',
          'delve',
        },
      },
    },

    -- }}}

    -- {{{Runtime and UI
    { 'igorlfs/nvim-dap-view', opts = {}, lazy = true },
    { 'rcarriga/nvim-dap-ui', dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' } },
    { 'theHamsta/nvim-dap-virtual-text', opts = {}, lazy = true },
    {
      'carcuis/dap-breakpoints.nvim',
      -- 'blehrer/dap-breakpoints.nvim',
      -- branch = 'multiprop-breakpoint-editing'
      -- dir = vim.fs.joinpath(os.getenv 'WORKSPACE', 'blehrer', 'dap-breakpoints.nvim'),
      ---@module 'dap-breakpoints'
      ---@type DapBpConfig
      opts = {
        virtual_text = {
          preset = 'icons_only',
          order = 'c',
        },
      },
      dependencies = {
        'Weissle/persistent-breakpoints.nvim',
        opts = {},
      },
      lazy = true,
    },
    -- }}}

    -- {{{Language Support Adapters

    -- {{{ Golang
    {
      'leoluz/nvim-dap-go',
      opts = {},
      ft = 'go',
    },
    -- }}}
    -- {{{Lua
    {
      'jbyuki/one-small-step-for-vimkind',
      lazy = true,
    },
    -- }}}
    -- {{{ Python
    {
      'mfussenegger/nvim-dap-python',
      lazy = true,
    },
    -- }}}

    -- }}}
  },
  ---@return dap.Configuration
  config = function(_, _)
    local dap, dapui = require 'dap', require 'dap-view'

    -- {{{UI Event listeners
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
    -- }}}

    -- {{{UI colors and symbols
    vim.cmd 'hi DapBreakpointColor guifg=#fa4848'
    vim.fn.sign_define('DapBreakpoint', { text = '⦿', texthl = 'DapBreakpointColor', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '⨕', texthl = 'DapBreakpointColor', linehl = '', numhl = '' })
    -- }}}

    -- {{{Adapters

    -- {{{Python
    require('dap-python').setup('python', {
      justMyCode = true,
      showReturnValue = true,
    })
    -- }}}

    -- {{{Lua
    dap.configurations.lua = {
      {
        type = 'lua',
        request = 'attach',
        name = 'Run this file',
        start_neovim = {},
      },
      {
        type = 'lua',
        request = 'attach',
        name = 'Attach to running Neovim instance (port = 8086)',
        port = 8086,
      },
    }

    dap.adapters.lua = function(callback, conf)
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
    ---}}}

    -- {{{Node
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

    local filetypes = require 'mason-nvim-dap.mappings.filetypes'
    for _, ft in ipairs(filetypes['node2']) do
      dap.configurations[ft] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = ('%s Launch file'):format(require('mini.icons').get('filetype', ft)),
          program = '${file}',
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = ('%s Attach'):format(require('mini.icons').get('filetype', ft)),
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = ('%s Debug Playwright Tests'):format(require('mini.icons').get('filetype', ft)),
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
    end

    -- }}}

    -- {{{ Golang
    dap.adapters.delve = {
      type = 'server',
      port = '${port}',
      executable = {
        command = os.getenv('TERM'):gsub('.*-', ''),
        args = { 'dlv', 'dap', '-l', '127.0.0.1:${port}' },
      },
    }
    -- }}}
    ---}}}

    -- }}}
  end,
  ---@return LazyKeysSpec[]
  keys = function()
    -- {{{Keys
    return {
      {
        '<leader>d<space>',
        function()
          require('dap').continue()
        end,
        desc = '[D]ebug: Start/Continue',
      },
      {
        '<F5>',
        function()
          require('dap').continue()
        end,
        desc = '[D]ebug: Start/Continue',
      },

      {
        '<leader>dl',
        function()
          require('dap').step_into()
        end,
        desc = '[D]ebug: Step Into',
      },
      {
        '<F1>',
        function()
          require('dap').step_into()
        end,
        desc = '[D]ebug: Step Into',
      },

      {
        '<leader>dj',
        function()
          require('dap').step_over()
        end,
        desc = '[D]ebug: Step Over',
      },
      {
        '<F2>',
        function()
          require('dap').step_over()
        end,
        desc = '[D]ebug: Step Over',
      },

      {
        '<leader>d',
        function()
          require('dap').step_out()
        end,
        desc = '[D]ebug: Step Out',
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
        end,
        desc = 'Toggle [b]reakpoint',
      },

      {
        '<leader>be',
        function()
          require('dap-breakpoints.api').edit_property { all = true }
        end,
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

      {
        '<leader>du',
        function()
          require('dap-view').toggle(true)
        end,
        desc = '[D]ebug: See last session result.',
      },
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
    }
    ---}}}
  end,
}

--- vim: ts=2 sts=2 sw=2 et foldmethod=marker
