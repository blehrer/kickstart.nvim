-- My keymaps
--
RenameFile = function()
  local old_name = vim.fn.expand '%'
  local new_name = vim.fn.input('New file name: ', vim.fn.expand '%', 'file')
  if new_name ~= '' and new_name ~= old_name then
    vim.fn.execute(':saveas ' + new_name)
    vim.fn.execute(':silent !rm ' + old_name)
  end
end

return {
  vim.keymap.set('n', '<leader>w', ':w<cr>', { desc = '[W]rite' }),
  vim.keymap.set('n', '<leader>q', ':q<cr>', { desc = '[Q]uit' }),
  vim.keymap.set('n', '<A-j>', 'a<cr><esc>k$', { desc = 'Split lines (opposite of `shift+j`)' }),
  vim.keymap.set('n', '<C-j>', 'a<cr><esc>k$', { desc = 'Split lines (opposite of `shift+j`)' }),
  vim.keymap.set('n', '<F18>', ':lua RenameFile()<cr>', { desc = 'Rename file' }),
  vim.keymap.set('n', '<leader>l', ':Lazy<cr>', { desc = '[L]azy plugin manager' }),
  vim.cmd.cabbrev('w!!', 'w !SUDO_ASKPASS="/usr/bin/pass $USER" sudo --askpass tee % > /dev/null'),
}
