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
local lsp_apply = require('facets.lsp_apply')

lsp_apply.setup_dap_defaults()

local dap_log = vim.fn.stdpath('data') .. '/dap-last.log'

local function append_dap_log(text)
  if not text or text == '' then
    return
  end
  local prior = vim.fn.filereadable(dap_log) == 1 and table.concat(vim.fn.readfile(dap_log), '\n') .. '\n' or ''
  vim.fn.writefile({ prior .. text }, dap_log)
end

dap.listeners.after.event_output['dap-log'] = function(_, body)
  if body and body.output then
    append_dap_log(body.output)
  end
end

dap.listeners.after.event_exited['dap-log'] = function(_, body)
  local code = body and body.exitCode or '?'
  local msg = ('DAP process exited (code %s) — log: %s'):format(tostring(code), dap_log)
  if code == 0 or code == '0' then
    vim.notify(msg, vim.log.levels.INFO)
  else
    vim.notify(msg, vim.log.levels.ERROR)
  end
  append_dap_log(('\n[%s] exit %s\n'):format(os.date('!%H:%M:%S'), tostring(code)))
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
dap.listeners.before.event_exited.dapview = function(_, body)
  local code = body and body.exitCode
  if code and code ~= 0 then
    vim.notify(('DAP failed (exit %d) — <leader>du to inspect, log: %s'):format(code, dap_log), vim.log.levels.ERROR)
    return
  end
  dapview.close()
end

local function dap_continue()
  lsp_apply.apply_for_buffer(vim.api.nvim_get_current_buf())
  dap.continue()
end

vim.keymap.set('n', '<leader>d<space>', dap_continue, { desc = 'Debug continue' })
vim.keymap.set('n', '<F5>', dap_continue, { desc = 'Debug continue' })
vim.keymap.set('n', '<leader>dl', dap.step_into, { desc = 'Debug step into' })
vim.keymap.set('n', '<leader>dj', dap.step_over, { desc = 'Debug step over' })
vim.keymap.set('n', '<leader>dk', dap.step_out, { desc = 'Debug step out' })
vim.keymap.set('n', '<leader>b', function()
  require('dap-breakpoints.api').toggle_breakpoint()
end, { desc = 'Toggle breakpoint' })
vim.keymap.set('n', '<leader>du', require('config.pane').toggle(function()
  dapview.toggle(true)
end), { desc = 'Debug UI toggle' })

local function open_dap_log()
  if vim.fn.filereadable(dap_log) ~= 1 then
    vim.notify('No DAP log yet: ' .. dap_log, vim.log.levels.WARN)
    return
  end
  vim.cmd('edit ' .. vim.fn.fnameescape(dap_log))
end

vim.api.nvim_create_user_command('DapLog', open_dap_log, { desc = 'Open last DAP log' })
vim.api.nvim_create_user_command('NxDapLog', open_dap_log, { desc = 'Open last DAP log (alias)' })
