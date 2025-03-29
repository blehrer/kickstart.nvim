local esc = vim.keycode '<Esc>'
-- Log to console
vim.fn.setreg('l', 'yo' .. 'console.log("' .. esc .. 'pa:", ' .. esc .. 'pa)')
