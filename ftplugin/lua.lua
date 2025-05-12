vim.keymap.set('n', '<leader>dl', function()
  require('osv').launch { port = 8086 }
end, {
  noremap = true,
  buffer = 0,
  desc = '[D]ebug: Launch neovim [l]ua debugger',
})

local esc = vim.keycode '<Esc>'
-- Log highlighted phase as a notification
vim.fn.setreg('l', 'yo' .. 'vim.notify(("' .. esc .. 'pa: %s"):format(vim.inspect(' .. esc .. 'pa)))' .. esc)
