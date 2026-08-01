if vim.g.vscode then return end

vim.pack.add({ 'https://github.com/stevearc/oil.nvim' })

require('oil').setup({
  preview_win = {
    update_on_cursor_moved = true,
    show_hidden = true,
  },
})

vim.keymap.set('n', '-', function()
  require('oil').open()
end, { desc = 'Open parent directory (oil)' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'oil',
  group = vim.api.nvim_create_augroup('nvim-new-oil', { clear = true }),
  callback = function(args)
    vim.keymap.set('n', '~', function()
      vim.api.nvim_set_current_dir(require('oil').get_current_dir(0) or '.')
    end, { buffer = args.buf, desc = 'Set cwd to Oil directory' })
  end,
})
