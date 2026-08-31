if vim.g.vscode then
	return
end

-- ponytail: centers ui2 cmdline; requires config.ui2 loaded first from init.lua
vim.pack.add({ "https://github.com/rachartier/tiny-cmdline.nvim" })

local function brighten_cmdline()
	local dark = vim.o.background == "dark"
	vim.api.nvim_set_hl(0, "TinyCmdlineBorder", { fg = dark and "#7dcfff" or "#2563eb", bold = true })
	vim.api.nvim_set_hl(0, "TinyCmdlineNormal", {
		bg = dark and "#24283b" or "#f0f0f0",
		fg = dark and "#e6e6e6" or "#1a1a1a",
	})
	vim.api.nvim_set_hl(0, "CmdlinePrompt", { fg = dark and "#ffcc00" or "#b45309", bold = true })
	vim.api.nvim_set_hl(0, "Cmdline", { fg = dark and "#e6e6e6" or "#1a1a1a", bold = true })
end

require("tiny-cmdline").setup({
	border = "rounded",
	native_types = {}, -- ponytail: try centered search; restore { '/', '?' } if it feels wrong
})

brighten_cmdline()
vim.api.nvim_create_autocmd("ColorScheme", {
	desc = "Keep centered cmdline easy to spot",
	callback = brighten_cmdline,
})
