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

local function truncate_suffix(text, max)
  if max <= 0 or #text <= max then
    return text
  end
  return text:sub(-max)
end

function M.filename()
  local path = vim.api.nvim_buf_get_name(0)
  local name = path ~= '' and vim.fn.fnamemodify(path, ':.') or '[No Name]'
  if name == '' then
    name = vim.fn.fnamemodify(path, ':t')
  end

  -- ponytail: byte length, not display width; upgrade with vim.fn.strwidth if needed
  local reserved = 36 + #M.mode() + #M.git()
  local max = vim.o.columns - reserved
  max = math.max(max, 8)

  return truncate_suffix(name, max)
end

function M.setup()
  vim.opt.statusline = table.concat({
    '%<',
    '%#ModeMsg#',
    '%{% v:lua.require("config.statusline").mode() %}',
    '%#Normal#',
    '%{% v:lua.require("config.statusline").git() %}',
    '%=',
    ' %{% v:lua.require("config.statusline").filename() %} ',
    ' %y ',
    '%l:%c ',
    '%P',
    ' [b: %n]',
  }, '')
end

return M
