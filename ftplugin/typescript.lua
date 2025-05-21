-- Log highlighted phase as a notification
vim.keymap.set('v', '<leader>cl', function()
  local esc = vim.keycode '<Esc>'
  local macro = table.concat({
    'yo',
    'console.log(`',
    esc,
    'pa',
    ': ${',
    esc,
    'pa',
    '}`)',
    esc,
  }, '')
  vim.fn.setreg('l', macro)
  vim.cmd 'norm @l'
end, { desc = '[C]ode: [L]og highlighted as a notification' })
