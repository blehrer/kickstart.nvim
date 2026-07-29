vim.pack.add({
  'https://github.com/nvim-neotest/neotest',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/thenbe/neotest-playwright',
})

local pw = require('nx.playwright')
local pw_adapter = pw.wrap_adapter(require('neotest-playwright').adapter(pw.adapter_options()))

require('neotest').setup({
  adapters = { pw_adapter },
  consumers = {
    playwright = require('neotest-playwright.consumers').consumers,
  },
})

vim.keymap.set('n', '<leader>tr', function()
  require('neotest').run.run()
end, { desc = 'Test: run nearest' })

vim.keymap.set('n', '<leader>tR', function()
  require('neotest').run.run(vim.fn.expand('%'))
end, { desc = 'Test: run file' })

vim.keymap.set('n', '<leader>tl', function()
  require('neotest').run.run_last()
end, { desc = 'Test: run last' })

vim.keymap.set('n', '<leader>ts', function()
  require('neotest').summary.toggle()
end, { desc = 'Test: summary' })

vim.keymap.set('n', '<leader>to', function()
  require('neotest').output.open({ enter = true })
end, { desc = 'Test: output' })

vim.keymap.set('n', '<leader>td', pw.run_dap, { desc = 'Test: debug (Playwright DAP on spec)' })

vim.keymap.set('n', '<leader>te', pw.pick_e2e_env, { desc = 'Test: pick e2e env (.env.{name})' })

vim.keymap.set('n', '<leader>tp', '<cmd>NeotestPlaywrightProject<cr>', { desc = 'Test: Playwright browser project' })

vim.keymap.set('n', '<leader>tP', pw.pick_flags, { desc = 'Test: Playwright CLI flags (<leader>tP)' })

vim.keymap.set('n', '<leader>tx', '<cmd>NeotestPlaywrightRefresh<cr>', { desc = 'Test: refresh Playwright list' })

vim.keymap.set('n', '<leader>ta', function()
  require('neotest').playwright.attachment()
end, { desc = 'Test: open trace/video attachment' })
