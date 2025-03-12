vim.keymap.set('n', '<leader>tt', function()
  local picker = require('snacks').picker 'colorschemes'
  picker.selected(picker, {})
end, { desc = 'Colorscheme picker' })
return {
  { 'folke/tokyonight.nvim' },
  { 'rose-pine/neovim' },
  { 'sho-87/kanagawa-paper.nvim' },
  { 'comfysage/evergarden' },
  { 'nyoom-engineering/oxocarbon.nvim' },
  { 'catppuccin/nvim' },
  { 'foxoman/vim-helix' },
}
