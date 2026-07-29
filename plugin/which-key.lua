vim.pack.add({ 'https://github.com/folke/which-key.nvim' })

require('which-key').setup({
  delay = 0,
  icons = {
    mappings = vim.g.have_nerd_font,
    keys = vim.g.have_nerd_font and {} or nil,
  },
  spec = {
    { '<leader>s', group = 'Search (Snacks)' },
    { '<leader>g', group = 'Git' },
    { '<leader>d', group = 'Debug' },
    { '<leader>t', group = 'Tests' },
    { '<leader>r', group = 'Refactor' },
    { '<leader>u', group = 'UI toggles' },
    { '<leader>c', group = 'Code' },
    { '<leader>x', group = 'Trouble' },
  },
})
