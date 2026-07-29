vim.keymap.set('n', '<leader>nx', function()
  require('nx.menu').run()
end, { desc = 'Nx: run target (menu)' })

vim.keymap.set('n', '<leader>nt', function()
  require('nx.menu').run({ target = 'e2e', prefer_current_project = true })
end, { desc = 'Nx: run e2e for current project' })

vim.schedule(function()
  require('nx.playwright_cli').get()
  local root = require('nx.workspace').root()
  if root then
    require('nx.discover').list(root, 'e2e')
  end
end)
