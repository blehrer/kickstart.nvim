---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'mawkler/refjump.nvim',
  after = { 'nvim-treesitter' },
  opts = {
    integrations = {
      demicolon = {
        enable = false,
      },
    },
  },
  event = 'LspAttach',
}
