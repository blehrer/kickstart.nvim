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
}
