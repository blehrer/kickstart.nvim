local esc = vim.keycode '<Esc>'
local cr = vim.keycode '<CR>'
local newline = '\n'

-- Log to console
vim.fn.setreg('l', 'yo' .. 'print("' .. esc .. 'pa:", vim.inspect(' .. esc .. 'pa))')
-- Markdown link (starting from "[txt]", yield "[txt][txt]" on current line, and "[txt]: https://" on last line)
vim.fn.setreg('k', 'ya[$p' .. 'G:put' .. cr .. '$a: https://')
vim.api.nvim_create_user_command('Mdlink', 'ya[$p' .. 'G:put' .. cr .. '$a: https://', {
  desc = [[
  Markdown link.
  Starting from "[txt]", yield "[txt][txt]" on current line, and "[txt]: https://" on last line)
  ]],
})
