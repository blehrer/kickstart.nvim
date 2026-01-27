---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'nvim-treesitter/nvim-treesitter',
  lazy = true,
  build = ':TSUpdate',
  opts = {},
}
