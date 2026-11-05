if vim.g.vscode then
	return
end

vim.pack.add({
	"https://github.com/kevinhwang91/nvim-bqf",
	"https://github.com/folke/trouble.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/folke/todo-comments.nvim",
})

require("bqf").setup({
	filter = {
		fzf = {
			extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│" },
		},
	},
})

local nx_trouble = require('nx.trouble')
local facet_trouble = require('facets.trouble')

require('trouble').setup({})
facet_trouble.register_sources()
-- trouble.setup resets options; re-declare facet modes here or they vanish.
require('trouble').setup({
  modes = vim.tbl_extend('force', {
    nx_diagnostics = {
      mode = 'diagnostics',
      filter = nx_trouble.make_filter('nx_diagnostics'),
    },
    nx_diagnostics_dependents = {
      mode = 'diagnostics',
      filter = nx_trouble.make_filter('nx_diagnostics_dependents'),
    },
  }, facet_trouble.modes),
})

require("todo-comments").setup({ signs = false })

vim.keymap.set("n", "<leader>z", function()
	require("bqf").toggle()
end, { desc = "Toggle quickfix enhancements" })

local pane = require('config.pane')

vim.keymap.set('n', '<leader>xx', pane.toggle('Trouble diagnostics toggle'), { desc = 'Trouble diagnostics' })
vim.keymap.set(
	'n',
	'<leader>xX',
	pane.toggle('Trouble diagnostics toggle filter.buf=0'),
	{ desc = 'Trouble buffer diagnostics' }
)
vim.keymap.set('n', '<leader>xt', pane.toggle('TodoTrouble'), { desc = 'Todo comments (Trouble)' })
vim.keymap.set('n', '<leader>xq', pane.toggle('Trouble qflist toggle'), { desc = 'Trouble quickfix' })
vim.keymap.set('n', '<leader>xp', pane.toggle(function()
	nx_trouble.open({ include_dependents = false })
end), { desc = 'Trouble Nx project diagnostics' })
vim.keymap.set('n', '<f3>', pane.toggle(function()
	nx_trouble.open({ include_dependents = false })
end), { desc = 'Trouble Nx project diagnostics' })
vim.keymap.set('n', '<leader>xP', pane.toggle(function()
	nx_trouble.open({ include_dependents = true })
end), { desc = 'Trouble Nx project + dependents diagnostics' })
vim.keymap.set("n", "<leader>xe", function()
	facet_trouble.pick()
end, { desc = "Trouble project check (facet picker)" })
vim.keymap.set("n", "<leader>xE", function()
	facet_trouble.open_eslint()
end, { desc = "Trouble ESLint project lint (npx eslint)" })
vim.keymap.set("n", "<leader>xT", function()
	facet_trouble.open_tsc()
end, { desc = "Trouble tsc project check (tsc --noEmit)" })
