if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/igorlfs/nvim-dap-view',
  'https://github.com/Weissle/persistent-breakpoints.nvim',
  'https://github.com/Carcuis/dap-breakpoints.nvim',
})

require('persistent-breakpoints').setup({})
require('dap-breakpoints').setup({
  virtual_text = { preset = 'icons_only', order = 'c' },
})

local dap = require('dap')
local dapview = require('dap-view')

local function js_debug_server()
  local path = vim.fn.stdpath('data') .. '/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js'
  if vim.fn.filereadable(path) == 1 then
    return path
  end
  return nil
end

local js_server = js_debug_server()
if js_server then
  dap.adapters['pwa-node'] = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
      command = 'node',
      args = { js_server, '${port}' },
    },
  }
end

dap.listeners.before.attach.dapview = function()
  dapview.open()
end
dap.listeners.before.launch.dapview = function()
  dapview.open()
end
dap.listeners.before.event_terminated.dapview = function()
  dapview.close()
end
dap.listeners.before.event_exited.dapview = function()
  dapview.close()
end

vim.keymap.set('n', '<leader>d<space>', dap.continue, { desc = 'Debug continue' })
vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug continue' })
vim.keymap.set('n', '<leader>dl', dap.step_into, { desc = 'Debug step into' })
vim.keymap.set('n', '<leader>dj', dap.step_over, { desc = 'Debug step over' })
vim.keymap.set('n', '<leader>dk', dap.step_out, { desc = 'Debug step out' })
vim.keymap.set('n', '<leader>b', function()
  require('dap-breakpoints.api').toggle_breakpoint()
end, { desc = 'Toggle breakpoint' })
vim.keymap.set('n', '<leader>du', function()
  dapview.toggle(true)
end, { desc = 'Debug UI toggle' })
