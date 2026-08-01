vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

if vim.g.vscode then
  require('config.cursor')
  return
end

require('config.ui2')
require('config.options')
require('config.statusline').setup()
require('config.keymaps')
require('config.autocmds')
