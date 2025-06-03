---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'kevinhwang91/nvim-bqf',
  ft = 'qf',
  ---@module 'bqf.config'
  ---@type BqfConfig
  opts = {},
  dependencies = {
    {
      'junegunn/fzf',
      config = function()
        vim.fn['fzf#install']()
      end,
    },
    { 'folke/which-key.nvim' },
  },
  keys = {
    {
      '<leader>z',
      function()
        local bqf = require 'bqf'
        bqf.toggle()
      end,
    },
  },
}
