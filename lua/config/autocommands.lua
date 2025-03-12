vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown' },
  callback = function()
    vim.schedule(function()
      vim.keymap.set('n', '<LocalLeader>p', ':TogglePeek<cr>', {
        desc = 'Toggle markdown preview (peek.nvim)',
        buffer = vim.api.nvim_get_current_buf(),
      })
    end)
  end,
})
