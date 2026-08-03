if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/windwp/nvim-autopairs',
  'https://github.com/monaqa/dial.nvim',
  'https://github.com/gaoDean/autolist.nvim',
})

require('nvim-autopairs').setup({})

require('config.dial').setup()

require('autolist').setup({})

local list_fts = { 'markdown', 'text', 'tex', 'plaintex' }
vim.api.nvim_create_autocmd('FileType', {
  pattern = list_fts,
  group = vim.api.nvim_create_augroup('autolist-keys', { clear = true }),
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('i', '<CR>', '<CR><cmd>AutolistNewBullet<cr>', opts)
    vim.keymap.set('n', '<CR>', '<cmd>AutolistToggleCheckbox<cr><CR>', opts)
  end,
})
