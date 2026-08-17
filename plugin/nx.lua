if vim.g.vscode then return end

vim.keymap.set('n', '<leader>nx', function()
  require('nx.menu').run()
end, { desc = 'Nx: run target (menu)' })

vim.keymap.set('n', '<leader>nt', function()
  require('nx.menu').run({ target = 'e2e', prefer_current_project = true })
end, { desc = 'Nx: run e2e for current project' })
