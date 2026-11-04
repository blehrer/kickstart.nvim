if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/tpope/vim-dadbod',
  'https://github.com/kristijanhusak/vim-dadbod-ui',
  'https://github.com/kristijanhusak/vim-dadbod-completion',
})

vim.g.db_ui_use_nerd_fonts = 1

-- vim.g.dbs = {
--   dev_db = 'postgresql://user:password@localhost:5432/my_database',
--   staging_db = 'mysql://user:password@staging-host:3306/staging_db',
-- }

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('dadbod-completion', { clear = true }),
  pattern = { 'sql', 'mysql', 'plsql' },
  callback = function(event)
    vim.bo[event.buf].omnifunc = 'vim_dadbod_completion#omni'

    local ok, cmp = pcall(require, 'cmp')
    if ok then
      cmp.setup.buffer({ sources = { { name = 'vim-dadbod-completion' } } })
    end
  end,
})
