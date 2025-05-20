return {
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
  lazy = true,
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
}
