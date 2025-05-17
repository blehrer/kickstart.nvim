do
  return {}
end
return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'haydenmeade/neotest-jest',
      'thenbe/neotest-playwright',
      'nvim-telescope/telescope.nvim',
    },
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
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(
        opts.adapters,
        require 'neotest-jest' {
          jestCommand = 'npm test --',
          jestConfigFile = 'custom.jest.config.ts',
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        }
      )
      table.insert(
        opts.adapters,
        require 'neotest-playwright' {
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
          },
        }
      )
    end,
  },
}
