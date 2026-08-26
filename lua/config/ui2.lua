vim.o.cmdheight = 0
vim.o.winborder = "rounded"

require("vim._core.ui2").enable({
	msg = {
		targets = "cmd",
		cmd = { height = 0.5 },
		msg = { height = 0.5, timeout = 4000 },
		pager = { height = 1 },
	},
})
