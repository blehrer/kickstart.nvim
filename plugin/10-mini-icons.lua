if vim.g.vscode then return end

vim.pack.add({ 'https://github.com/nvim-mini/mini.icons' })

require('mini.icons').setup({})
require('mini.icons').mock_nvim_web_devicons()
