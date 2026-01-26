---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local ts = require 'nvim-treesitter'
    ts.setup {}
    local ensure_installed = {
      'bash',
      'comment',
      'css',
      'diff',
      'dockerfile',
      'git_config',
      'git_rebase',
      'gitattributes',
      'gitconfig',
      'gitignore',
      'go',
      'goctl',
      'gomod',
      'gotmpl',
      'gowork',
      'graphql',
      'html',
      'hyprlang',
      'java',
      'javadoc',
      'javascript',
      'json',
      'kotlin',
      'lua',
      'make',
      'markdown',
      'markdown_inline',
      'mermaid',
      'python',
      'query',
      'sql',
      'terraform',
      'tsx',
      'typescript',
      'vim',
      'yaml',
    }
    ts.install(ensure_installed)
  end,
}
