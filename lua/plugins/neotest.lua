require('lazy.types')
---@type LazyPluginSpec[]
return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      {
        'thenbe/neotest-playwright',
        dependencies = 'nvim-telescope/telescope.nvim',
        keys = {
          {
            '<leader>nta',
            function()
              require('neotest').playwright.attachment()
            end,
            desc = 'Launch test attachment',
          },
        }
      }
    },
    config = function()
      require('neotest').setup({
        adapters = {
          require('neotest-playwright').adapter({
            options = {
              persist_project_selection = true,
              enable_dynamic_test_discovery = true,
            },
          }),
        },
        consumers = {
          -- add to your list of consumers
          playwright = require('neotest-playwright.consumers').consumers,
        },
      })
    end,
  }

}
