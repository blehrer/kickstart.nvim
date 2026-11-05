if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/tpope/vim-dadbod',
  'https://github.com/kristijanhusak/vim-dadbod-ui',
})

vim.g.db_ui_use_nerd_fonts = 1

-- vim.g.dbs = {
--   dev_db = 'postgresql://user:password@localhost:5432/my_database',
--   staging_db = 'mysql://user:password@staging-host:3306/staging_db',
-- }

