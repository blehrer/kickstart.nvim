local esc = vim.keycode '<Esc>'
-- Log to console
vim.fn.setreg('l', 'yo' .. 'print("' .. esc .. 'pa:", vim.inspect(' .. esc .. 'pa))')
