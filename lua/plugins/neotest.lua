---@module lazy.types
---@type LazyPluginSpec
return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',

    -- {{{Adapters
    { 'haydenmeade/neotest-jest' },
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
    -- }}}
  },
  lazy = true,
  config = function(_, opts)
    require('neotest').setup {
      adapters = {
        require('neotest-playwright').adapter {
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
          },
        },

        require 'neotest-jest' {
          jestCommand = 'npm test --',
          jestConfigFile = 'custom.jest.config.ts',
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        },
      },
      consumers = {
        playwright = require('neotest-playwright.consumers').consumers,
      },
    }
  end,
  keys = {
    {
      '<leader>tl',
      function()
        require('neotest').run.run_last()
      end,
      desc = 'Run Last Test',
    },
    {
      '<leader>tL',
      function()
        require('neotest').run.run_last { strategy = 'dap' }
      end,
      desc = 'Debug Last Test',
    },
    {
      '<leader>tw',
      "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>",
      desc = 'Run Watch',
    },
  },
}
--- vim: ts=2 sts=2 sw=2 et foldmethod=marker
