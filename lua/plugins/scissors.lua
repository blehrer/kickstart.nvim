---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'chrisgrieser/nvim-scissors',
  lazy = false,
  ---@module 'scissors.types'
  ---@type Scissors.Config
  opts = {
    snippetDir = vim.fs.joinpath(vim.fn.stdpath 'config', 'snippets', 'vscode'),
  },
  dependencies = { 'folke/snacks.nvim' },
  ---@type LazyKeysSpec[]
  keys = {
    {
      '<leader>cse',
      function()
        require('scissors').editSnippet()
      end,
      desc = '[C]ode: edit snippet',
    },
    {
      '<leader>csa',
      function()
        require('scissors').addNewSnippet()
      end,
      desc = '[C]ode: add snippet',
      mode = { 'n', 'x' },
    },
    {
      '<leader>csa',
      function()
        require('scissors').addNewSnippet "'<,'>"
      end,
      desc = '[C]ode: add snippet from selection',
      mode = { 'v' },
    },
  },
}
