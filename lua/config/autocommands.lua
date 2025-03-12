vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown' },
  callback = function()
    vim.schedule(function()
      vim.keymap.set('n', '<leader>p', ':TogglePeek<cr>', { desc = 'Toggle markdown preview (peek.nvim)' })
    end)
  end,
})

