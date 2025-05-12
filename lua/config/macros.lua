local cr = vim.keycode '<CR>'

-- Markdown link (starting from "[txt]", yield "[txt][txt]" on current line, and "[txt]: https://" on last line)
vim.fn.setreg('k', 'ya[$p' .. 'G:put' .. cr .. '$a: https://')
vim.api.nvim_create_user_command('Mdlink', 'ya[$p' .. 'G:put' .. cr .. '$a: https://', {
  desc = [[
  Markdown link.
  Starting from "[txt]", yield "[txt][txt]" on current line, and "[txt]: https://" on last line)
  ]],
})
