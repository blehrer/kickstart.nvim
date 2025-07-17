---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'kevinhwang91/nvim-bqf',
  ft = 'qf',
  dependencies = {
    {
      'junegunn/fzf',
    },
  },
  ---@module "bqf.config"
  ---@type BqfConfig
  opts = {
    filter = {
      fzf = {
        extra_opts = { '--bind', 'ctrl-o:toggle-all', '--delimiter', '│' },
      },
    },
  },
  keys = {
    {
      '<leader>z',
      function()
        require('bqf').toggle()
      end,
      desc = 'Toggle quickfix list',
    },
  },
}
