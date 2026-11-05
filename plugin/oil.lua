if vim.g.vscode then return end

vim.pack.add({ 'https://github.com/stevearc/oil.nvim' })

require('oil').setup({
  preview_win = {
    update_on_cursor_moved = true,
    show_hidden = true,
  },
  skip_confirm_for_simple_edits = true,
})

vim.keymap.set('n', '-', function()
  require('oil').open()
end, { desc = 'Open parent directory (oil)' })

