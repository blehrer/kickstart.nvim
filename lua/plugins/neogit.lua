---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'sindrets/diffview.nvim', -- optional - Diff integration
    'folke/snacks.nvim', -- optional
  },
  opts = {},
  keys = {
    {
      '<leader>gs',
      function()
        require('neogit').open()
      end,
      desc = '[g]it status (neogit)',
    },
  },
}
