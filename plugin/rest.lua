if vim.g.vscode then return end

-- ponytail: vim.pack has no rockspec; git deps live at rtp root, not lua/ (see rest-nvim#559)
vim.pack.add({
  'https://github.com/lunarmodules/lua-mimetypes',
  'https://github.com/manoelcampos/xml2lua',
  'https://github.com/j-hui/fidget.nvim',
})

local pack = vim.fs.joinpath(vim.fn.stdpath('data'), 'site/pack/core/opt')
for _, name in ipairs({ 'lua-mimetypes', 'xml2lua' }) do
  package.path = package.path .. ';' .. vim.fs.joinpath(pack, name) .. '/?.lua'
end

require('fidget').setup({})

vim.pack.add({ 'https://github.com/rest-nvim/rest.nvim' })

vim.keymap.set('n', '<leader>hr', '<cmd>Rest run<cr>', { desc = 'HTTP: run request' })
vim.keymap.set('n', '<leader>hR', '<cmd>Rest last<cr>', { desc = 'HTTP: run last request' })
vim.keymap.set('n', '<leader>ho', '<cmd>Rest open<cr>', { desc = 'HTTP: open result pane' })
vim.keymap.set('n', '<leader>he', '<cmd>Rest env select<cr>', { desc = 'HTTP: select .env file' })
vim.keymap.set('n', '<leader>hE', '<cmd>Rest env show<cr>', { desc = 'HTTP: show .env file' })
vim.keymap.set('n', '<leader>hc', '<cmd>Rest cookies<cr>', { desc = 'HTTP: edit cookies' })
vim.keymap.set('n', '<leader>hl', '<cmd>Rest logs<cr>', { desc = 'HTTP: edit logs' })

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('nvim-new-rest', { clear = true }),
  pattern = 'http',
  callback = function(args)
    vim.keymap.set('n', '<CR>', '<cmd>Rest run<cr>', { buffer = args.buf, desc = 'HTTP: run request' })
  end,
})
