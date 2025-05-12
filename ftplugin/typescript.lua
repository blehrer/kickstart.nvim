local esc = vim.keycode '<Esc>'
-- Log highlighted phase
vim.fn.setreg('l', 'yo' .. 'console.log(`' .. esc .. 'pa' .. ': ${' .. esc .. 'pa' .. '}`)' .. esc)
