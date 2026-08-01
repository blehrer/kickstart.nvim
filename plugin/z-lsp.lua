if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/mason-org/mason-lspconfig.nvim',
  'https://github.com/folke/lazydev.nvim',
})

require('config.lsp').setup()
