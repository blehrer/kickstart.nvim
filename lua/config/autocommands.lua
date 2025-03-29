vim.api.nvim_create_augroup('bl-markdown', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'liquid' },
  group = 'bl-markdown',
  callback = function()
    vim.schedule(function()
      vim.keymap.set('n', '<LocalLeader>p', ':TogglePeek<cr>', {
        desc = 'Toggle markdown preview (peek.nvim)',
        buffer = vim.api.nvim_get_current_buf(),
      })
    end)
  end,
})
