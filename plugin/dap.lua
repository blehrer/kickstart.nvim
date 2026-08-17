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

  -- ponytail: monorepo .vscode/launch.json uses "node"; js-debug only registers as pwa-node
  if not dap.adapters.node then
    dap.adapters.node = function(cb, config)
      config.type = 'pwa-node'
      local native = dap.adapters['pwa-node']
      if type(native) == 'function' then
        native(cb, config)
      else
        cb(native)
      end
    end
  end
else
  vim.api.nvim_create_user_command('DapInstallJsDebug', function()
    vim.notify('Run :MasonInstall js-debug-adapter then restart nvim', vim.log.levels.ERROR)
  end, {})
end

local dap_log = vim.fn.stdpath('data') .. '/nx-dap-last.log'

local function append_dap_log(text)
  if not text or text == '' then
    return
  end
  local prior = vim.fn.filereadable(dap_log) == 1 and table.concat(vim.fn.readfile(dap_log), '\n') .. '\n' or ''
  vim.fn.writefile({ prior .. text }, dap_log)
end

dap.listeners.after.event_output['nx-dap-log'] = function(_, body)
  if body and body.output then
    append_dap_log(body.output)
  end
end

dap.listeners.after.event_exited['nx-dap-log'] = function(_, body)
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
dap.listeners.before.event_exited.dapview = function(session, body)
  local code = body and body.exitCode
  if code and code ~= 0 then
    vim.notify(('DAP failed (exit %d) — <leader>du to inspect, log: %s'):format(code, dap_log), vim.log.levels.ERROR)
    return
  end
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

vim.api.nvim_create_user_command('NxDapLog', function()
  if vim.fn.filereadable(dap_log) ~= 1 then
    vim.notify('No DAP log yet: ' .. dap_log, vim.log.levels.WARN)
    return
  end
  vim.cmd('edit ' .. vim.fn.fnameescape(dap_log))
end, { desc = 'Open last Playwright DAP log' })
