vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

require('config.ui2')
require('config.options')
require('config.statusline').setup()
require('config.keymaps')
require('config.autocmds')
