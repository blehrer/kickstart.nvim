require 'lazy.types'
---@type LazyPluginSpec
return {
  -- 'kanedo/jekyll.nvim',
  dir = '/Users/nobut/workspace/blehrer/jekyll.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  opts = {},
  ---@type LazyKeysSpec[]
  -- keys = {
  --   {
  --     '<leader>jd',
  --     ':JekyllDraft<cr>',
  --     mode = '',
  --     desc = 'New [J]ekyll [Draft]',
  --   },
  -- },
}
