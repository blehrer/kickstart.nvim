-- Dedicated vscode-neovim init. No plugin/ autoload — keymaps only.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

local repo = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand('<sfile>:p')), ':h:h')
package.path = repo .. '/lua/?.lua;' .. repo .. '/lua/?/init.lua;' .. package.path

require('config.keymaps')
