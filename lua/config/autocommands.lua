vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'liquid' },
  group = vim.api.nvim_create_augroup('bl-markdown', { clear = true }),
  callback = function()
    vim.schedule(function()
      vim.keymap.set('n', '<LocalLeader>p', ':TogglePeek<cr>', {
        desc = 'Toggle markdown preview (peek.nvim)',
        buffer = vim.api.nvim_get_current_buf(),
      })
    end)
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
