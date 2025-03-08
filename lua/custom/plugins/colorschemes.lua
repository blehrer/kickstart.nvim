return {
  {
    'lmantw/themify.nvim',

    lazy = false,
    priority = 999,

    opts = { -- see `:Telescope colorscheme`.
      'folke/tokyonight.nvim',
      'rose-pine/neovim',
      { 'sho-87/kanagawa-paper.nvim', priority = 1000 },
      { 'comfysage/evergarden', branch = 'mega' },
    },
  },
}
