-- Dedicated vscode-neovim init. No plugin/ autoload — keymaps only.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

local repo = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand('<sfile>:p')), ':h:h')
package.path = repo .. '/lua/?.lua;' .. repo .. '/lua/?/init.lua;' .. package.path

-- ponytail: embed unsets NVIM_APPNAME, so point packpath at kickstart datadir manually
local pack_site = vim.fn.expand('~/.local/share/' .. vim.fn.fnamemodify(repo, ':t') .. '/site')
vim.opt.packpath:prepend(pack_site)
vim.cmd('packadd dial.nvim')

require('config.keymaps')
require('config.dial').setup()
