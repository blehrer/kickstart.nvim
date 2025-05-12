local esc = vim.keycode '<Esc>'
-- Log highlighted phase
vim.fn.setreg('l', 'yo' .. 'print(f' .. esc .. 'pa' .. ': {' .. esc .. 'pa' .. '})' .. esc)
