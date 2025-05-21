vim.keymap.set('n', '<leader>ds', function()
  require('osv').launch { port = 8086 }
end, {
  noremap = true,
  buffer = 0,
  desc = '[D]ebug: Launch neovim lua debugg [s]erver',
})

-- Log highlighted phase as a notification
vim.keymap.set('v', '<leader>cl', function()
  local esc = vim.keycode '<Esc>'
  local macro = table.concat({
    'yo',
    'vim.notify(("',
    esc,
    'pa: %s"):format(vim.inspect(',
    esc,
    'pa)))',
    esc,
  }, '')

  vim.fn.setreg('l', macro)
  -- vim.notify(('setreg: %s'):format(vim.inspect(setreg)))
  vim.cmd 'norm @l'
end, { desc = '[C]ode: [L]og highlighted as a notification' })
