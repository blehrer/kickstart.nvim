local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, 'p')

local local_path = tmp .. '/local'
local base_path = tmp .. '/base'
local remote_path = tmp .. '/remote'
local merged_path = tmp .. '/merged'

vim.fn.writefile({ 'line one', 'line two local', 'line three' }, local_path)
vim.fn.writefile({ 'line one', 'line two', 'line three' }, base_path)
vim.fn.writefile({ 'line one', 'line two remote', 'line three' }, remote_path)
vim.fn.writefile({
  'line one',
  '<<<<<<< LOCAL',
  'line two local',
  '=======',
  'line two remote',
  '>>>>>>> REMOTE',
  'line three',
}, merged_path)

vim.env.LOCAL = local_path
vim.env.BASE = base_path
vim.env.REMOTE = remote_path
vim.env.MERGED = merged_path

vim.cmd('edit ' .. vim.fn.fnameescape(local_path))
vim.cmd('vnew ' .. vim.fn.fnameescape(base_path))
vim.cmd('vnew ' .. vim.fn.fnameescape(remote_path))
vim.cmd('belowright split ' .. vim.fn.fnameescape(merged_path))
vim.cmd('windo diffthis')

local detect = require('merge-tool-help.detect')
local layout = require('merge-tool-help.layout')
local render = require('merge-tool-help.render')

assert(detect.is_session(), 'session')
assert(detect.role_of_buf(vim.fn.bufnr(local_path)) == 'LOCAL', 'local role')
assert(detect.has_conflict_markers(vim.fn.bufnr(merged_path)), 'markers')

local x = layout.get_layout(nil, vim.api.nvim_get_current_win())
assert(#x.slots >= 2, 'slots')

local lines = render.render_tree({ type = 'leaf', slot = { index = 1 } }, 1, 1)
assert(#lines > 0, 'render')

vim.fn.delete(tmp, 'rf')
print('merge-tool-help: 5 checks passed')
