vim.bo.spelllang = 'en_us'
vim.g.bullets_outline_levels = { 'num', 'num', 'std-' }
vim.cmd 'map <S-Tab> <Plug>(bullets-promote)'
vim.cmd 'imap <S-Tab> <Plug>(bullets-promote)'
vim.cmd 'map <Tab> <Plug>(bullets-demote)'
vim.cmd 'imap <Tab> <Plug>(bullets-demote)'
