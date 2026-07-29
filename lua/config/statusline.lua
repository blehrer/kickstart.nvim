local M = {}

local mode_labels = {
  n = 'NORMAL',
  i = 'INSERT',
  v = 'VISUAL',
  V = 'V·LINE',
  ['\22'] = 'V·BLOCK',
  c = 'COMMAND',
  s = 'SELECT',
  S = 'S·LINE',
  R = 'REPLACE',
  t = 'TERMINAL',
}

function M.mode()
  return mode_labels[vim.fn.mode()] or vim.fn.mode():upper()
end

function M.git()
  local branch = vim.b.gitsigns_head
  if not branch or branch == '' then
    return ''
  end

  local line = '  󰘬 ' .. branch
  local status = vim.b.gitsigns_status
  if status and status ~= '' then
    line = line .. ' ' .. status
  end
  return line
end

function M.setup()
  vim.opt.statusline = table.concat({
    '%#ModeMsg#',
    '%{% v:lua.require("config.statusline").mode() %}',
    '%#Normal#',
    '%{% v:lua.require("config.statusline").git() %}',
    '%=',
    ' %y ',
    '%l:%c ',
    '%P',
  }, '')
end

return M
