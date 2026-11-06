if vim.g.vscode then return end

vim.pack.add({ 'https://github.com/stevearc/oil.nvim' })

-- Wipe hidden oil:// buffers before Oil's SessionLoadPost runs on :restart;
-- otherwise Oil's async loader falls back to the current window and fires
-- `BufReadPost oil://...` on the active file buffer, clobbering its filetype.
vim.api.nvim_create_autocmd('SessionLoadPost', {
  group = vim.api.nvim_create_augroup('kickstart_oil_session', { clear = true }),
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_buf_get_name(buf):match('^oil://')
        and #vim.fn.win_findbuf(buf) == 0
      then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end,
})

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

