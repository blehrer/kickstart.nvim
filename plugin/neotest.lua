if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/nvim-neotest/neotest',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/thenbe/neotest-playwright',
})

local pw = require('nx.playwright')
local registry = require('facets.registry')

local function playwright_neotest_enabled()
  if registry.has_facet('playwright.e2e', vim.loop.cwd()) then
    return true
  end
  return pw.find_pw_config_dir(vim.loop.cwd()) ~= nil
end

local adapters = {}
local neotest_opts = { adapters = adapters }

if playwright_neotest_enabled() then
  adapters[#adapters + 1] = pw.wrap_adapter(require('neotest-playwright').adapter(pw.adapter_options()))
  neotest_opts.consumers = {
    playwright = require('neotest-playwright.consumers').consumers,
  }
end

require('neotest').setup(neotest_opts)

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
