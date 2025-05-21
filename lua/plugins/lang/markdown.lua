local cmd = function(key)
  return vim.keycode('<D-%s>'):format(key)
end
---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'antonk52/markdowny.nvim',
  opts = { filetypes = { 'markdown' } },
  keys = {
    { cmd 'b', ":lua require('markdowny').bold()<cr>", mode = 'v', buffer = 0, desc = 'toggle bold' },
    { cmd 'i', ":lua require('markdowny').italic()<cr>", mode = 'v', buffer = 0, desc = 'toggle italics' },
    { cmd 'k', ":lua require('markdowny').link()<cr>", mode = 'v', buffer = 0, desc = 'toggle link' },
    { cmd 'e', ":lua require('markdowny').code()<cr>", mode = 'v', buffer = 0, desc = 'toggle code ticks' },
  },
}
