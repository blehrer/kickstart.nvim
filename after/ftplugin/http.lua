if vim.g.vscode then return end

vim.keymap.set('n', '<CR>', '<cmd>Rest run<cr>', { buffer = 0, desc = 'HTTP: run request' })
