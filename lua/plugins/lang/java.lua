---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'nvim-java/nvim-java',
  dependencies = {
    'neovim/nvim-lspconfig',
  },
  lazy = true,
  cond = function()
    local rp = require('lspconfig.util').root_pattern(require('java.config').root_markers)
    return rp(vim.uv.cwd()) and true or false
  end,
}
