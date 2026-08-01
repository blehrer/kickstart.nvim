if vim.g.vscode then return end

-- ponytail: centers ui2 cmdline; requires config.ui2 loaded first from init.lua
vim.pack.add({ 'https://github.com/rachartier/tiny-cmdline.nvim' })

require('tiny-cmdline').setup({
  border = nil, -- inherit vim.o.winborder
  native_types = {}, -- ponytail: try centered search; restore { '/', '?' } if it feels wrong
})
