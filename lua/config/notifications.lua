local M = {}

local function kind_for(level)
  if level == 'error' then
    return 'emsg'
  end
  if level == 'warn' then
    return 'wmsg'
  end
  return 'echomsg'
end

local hl_cache = {}

local function hl_id(group)
  if not group or group == 0 then
    return 0
  end
  if not hl_cache[group] then
    hl_cache[group] = vim.api.nvim_get_hl_id_by_name(group)
  end
  return hl_cache[group]
end

local function hl_for(level)
  if level == 'error' then
    return 'ErrorMsg'
  end
  if level == 'warn' then
    return 'WarningMsg'
  end
  return 0
end

local function notif_entry(notif)
  local head = { os.date('%R', notif.added), notif.icon or '', notif.level:upper() }
  if notif.title and notif.title ~= '' then
    head[#head + 1] = notif.title
  end
  head = table.concat(vim.tbl_filter(function(s)
    return s ~= ''
  end, head), ' ')

  local text = head ~= '' and (head .. '  ' .. notif.msg) or notif.msg
  return { kind_for(notif.level), { { 0, text, hl_id(hl_for(notif.level)) } }, false }
end

local function collect_entries()
  local entries = {}
  for _, notif in ipairs(Snacks.notifier.get_history({ reverse = true })) do
    entries[#entries + 1] = notif_entry(notif)
  end
  return entries
end

function M.show()
  local ui = require('vim._core.ui2')
  ui.check_targets()
  ui.msg.msg_history_show(collect_entries(), false)
end

return M
