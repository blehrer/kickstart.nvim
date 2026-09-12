if vim.g.vscode then
  return
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  group = vim.api.nvim_create_augroup('format-markdown', { clear = true }),
  callback = function()
    vim.bo.formatexpr = "v:lua.require'format.markdown'.formatexpr()"
    if not vim.bo.formatoptions:find('t', 1, true) then
      vim.bo.formatoptions = vim.bo.formatoptions .. 't'
    end
  end,
})
