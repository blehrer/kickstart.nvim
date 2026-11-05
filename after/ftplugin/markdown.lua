if vim.g.vscode then return end

-- gq → prettier on prose (tables/fences skipped); ref links guarded automatically.
-- Last resort: <!-- prettier-ignore-start --> … <!-- prettier-ignore-end --> in the file.
vim.bo.formatexpr = "v:lua.require'format.markdown'.formatexpr()"
if not vim.bo.formatoptions:find('t', 1, true) then
  vim.bo.formatoptions = vim.bo.formatoptions .. 't'
end

require('markdown_xanadu.init').setup_buffer(0)
