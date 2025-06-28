---@module 'lazy.types'
---@type LazyPluginSpec
return {
  -- 'kanedo/jekyll.nvim',
  dir = '/Users/nobut/workspace/blehrer/jekyll.nvim',
  optional = true,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  lazy = true,
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
