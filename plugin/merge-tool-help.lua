if vim.g.vscode then
  return
end

if vim.g.loaded_merge_tool_help then
  return
end
vim.g.loaded_merge_tool_help = true

require('merge-tool-help').setup()
