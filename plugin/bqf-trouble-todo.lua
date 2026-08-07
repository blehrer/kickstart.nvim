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

local nx_trouble = require("nx.trouble")

require("trouble").setup({
	modes = {
		nx_diagnostics = {
			mode = "diagnostics",
			filter = nx_trouble.make_filter("nx_diagnostics"),
		},
		nx_diagnostics_dependents = {
			mode = "diagnostics",
			filter = nx_trouble.make_filter("nx_diagnostics_dependents"),
		},
	},
})

require("todo-comments").setup({ signs = false })

vim.keymap.set("n", "<leader>z", function()
	require("bqf").toggle()
end, { desc = "Toggle quickfix enhancements" })

vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Trouble diagnostics" })
vim.keymap.set(
	"n",
	"<leader>xX",
	"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
	{ desc = "Trouble buffer diagnostics" }
)
vim.keymap.set("n", "<leader>xt", "<cmd>TodoTrouble<cr>", { desc = "Todo comments (Trouble)" })
vim.keymap.set("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", { desc = "Trouble quickfix" })
vim.keymap.set("n", "<leader>xp", function()
	nx_trouble.open({ include_dependents = false })
end, { desc = "Trouble Nx project diagnostics" })
vim.keymap.set("n", "<f3>", function()
	nx_trouble.open({ include_dependents = false })
end, { desc = "Trouble Nx project diagnostics" })
vim.keymap.set("n", "<leader>xP", function()
	nx_trouble.open({ include_dependents = true })
end, { desc = "Trouble Nx project + dependents diagnostics" })
