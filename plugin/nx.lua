local cache_warmed = false

local function warm_cache()
  if cache_warmed then
    return
  end
  cache_warmed = true
  require('nx.playwright_cli').get()
  local root = require('nx.workspace').root()
  if root then
    require('nx.discover').list(root, 'e2e')
  end
end

vim.keymap.set('n', '<leader>nx', function()
  warm_cache()
  require('nx.menu').run()
end, { desc = 'Nx: run target (menu)' })

vim.keymap.set('n', '<leader>nt', function()
  warm_cache()
  require('nx.menu').run({ target = 'e2e', prefer_current_project = true })
end, { desc = 'Nx: run e2e for current project' })
