local detect = require('merge-tool-help.detect')
local layout = require('merge-tool-help.layout')
local render = require('merge-tool-help.render')
local options = require('merge-tool-help.options')

local M = {}

---@class MergeToolHelpConfig
---@field keymap string
---@field width number
---@field diagram_scale number

M.config = {
  keymap = '<F1>',
  width = 72,
  diagram_scale = 1,
}

M.float_win = nil
M.float_buf = nil
M.tracked_win = nil
M.options_mode = false
M.ns_id = vim.api.nvim_create_namespace('merge-tool-help')
M.autocmd_group = nil
M._in_toggle = false
M._options_diagram_cache = nil
M._diff_pending = false
M._spinner_timer = nil
M._spinner_frame = 1

local SPINNER_FRAMES = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

local function spinner_text()
  return SPINNER_FRAMES[M._spinner_frame] .. ' updating diff'
end

function M.start_spinner()
  if M._spinner_timer then
    return
  end
  M._diff_pending = true
  M._spinner_frame = 1
  M.refresh()
  M._spinner_timer = vim.fn.timer_start(80, function()
    M._spinner_frame = (M._spinner_frame % #SPINNER_FRAMES) + 1
    if M._diff_pending and M.is_open() then
      M.refresh()
    end
  end, { ['repeat'] = -1 })
end

function M.stop_spinner()
  if M._spinner_timer then
    vim.fn.timer_stop(M._spinner_timer)
    M._spinner_timer = nil
  end
  M._diff_pending = false
end

function M.bind_diffupdate_hooks()
  options.on_diffupdate_start = function()
    M.start_spinner()
  end
  options.on_diffupdate_done = function()
    M.stop_spinner()
    if M.is_open() then
      M.refresh()
    end
  end
end

---@return boolean
function M.is_open()
  return M.float_win ~= nil and vim.api.nvim_win_is_valid(M.float_win)
end

function M.close()
  M.stop_spinner()
  options.cancel_diffupdate()
  if M.is_open() then
    pcall(vim.api.nvim_win_close, M.float_win, true)
  end
  M.float_win = nil
  M.float_buf = nil
  M.options_mode = false
end

---@param bufnr number
function M.apply_highlights(bufnr, highlights)
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, hl.row, hl.col, {
      end_col = hl.col + hl.length,
      hl_group = hl.hl_group,
      priority = 10,
    })
  end
end

function M.refresh()
  if not M.is_open() or not M.float_buf then
    return
  end

  local layout_data
  local diagram
  local highlights
  local active_slot

  if M.options_mode and M._options_diagram_cache then
    layout_data = M._options_diagram_cache.layout
    diagram = M._options_diagram_cache.diagram
    highlights = M._options_diagram_cache.highlights
  else
    layout_data = layout.get_layout(M.float_win, M.tracked_win)
    diagram, highlights = render.render_tree(layout_data.tree, layout_data.active_index, M.config.diagram_scale)

    for _, slot in ipairs(layout_data.slots) do
      if slot.index == layout_data.active_index then
        active_slot = slot
        break
      end
    end

    if M.options_mode then
      M._options_diagram_cache = {
        layout = layout_data,
        diagram = diagram,
        highlights = highlights,
      }
    end
  end

  if not active_slot and layout_data then
    for _, slot in ipairs(layout_data.slots) do
      if slot.index == layout_data.active_index then
        active_slot = slot
        break
      end
    end
  end

  local detail
  if M.options_mode then
    detail = render.options_detail(options.all_status_lines())
  else
    detail = render.pane_detail(active_slot)
  end

  local footer = nil
  if M.options_mode then
    footer = '[1-9] select  [Enter] go  [o] panes  [q] close'
  else
    footer = '[1-9] select pane  [Enter] go to pane  [o] options  [q] close'
  end
  if layout_data.other_tabs > 0 then
    footer = footer
      .. string.format('  (%d other tabpage(s) — diagram shows current tab only)', layout_data.other_tabs)
  end
  if M._diff_pending then
    footer = (footer or '') .. '  ' .. spinner_text()
  end

  local lines = render.compose(diagram, detail, footer)
  local width = math.min(M.config.width, math.max(40, vim.o.columns - 4))
  local max_line = 0
  for _, line in ipairs(lines) do
    max_line = math.max(max_line, vim.fn.strdisplaywidth(line))
  end
  width = math.min(math.max(width, max_line + 2), vim.o.columns - 4)

  vim.api.nvim_buf_set_option(M.float_buf, 'modifiable', true)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = M.float_buf })
  vim.api.nvim_buf_set_lines(M.float_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.float_buf, 'modifiable', false)

  M.apply_highlights(M.float_buf, highlights)

  if M.is_open() then
    vim.api.nvim_win_set_config(M.float_win, {
      width = width,
      height = #lines,
    })
  end
end

---@param index number
---@param confirm boolean|nil
function M.select_slot(index, confirm)
  local layout_data = layout.get_layout(M.float_win, M.tracked_win)
  local map = layout.slot_map(layout_data)
  local win_id = map[index]
  if not win_id then
    return
  end

  M.tracked_win = win_id
  M._options_diagram_cache = nil
  M.refresh()

  if confirm then
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_set_current_win(win_id)
    end
    M.close()
    return
  end

  if M.is_open() then
    vim.api.nvim_set_current_win(M.float_win)
  end
end

function M.confirm_selection()
  if not M.is_open() then
    return
  end

  if M.tracked_win and vim.api.nvim_win_is_valid(M.tracked_win) then
    vim.api.nvim_set_current_win(M.tracked_win)
  end
  M.close()
end

function M.toggle_options_mode()
  M.options_mode = not M.options_mode
  M._options_diagram_cache = nil
  M.refresh()
end

---@param exclude_win_id number|nil
function M.handle_diff_toggle(exclude_win_id, fn)
  M._in_toggle = true
  fn()
  options.apply_diffopt(exclude_win_id)
  M.refresh()
  if M.is_open() then
    vim.api.nvim_set_current_win(M.float_win)
  end
  M._in_toggle = false
end

function M.setup_keymaps()
  if not M.float_buf then
    return
  end

  local opts = { buffer = M.float_buf, silent = true }

  for i = 1, 9 do
    vim.keymap.set('n', tostring(i), function()
      M.select_slot(i, false)
    end, opts)
  end

  vim.keymap.set('n', '<CR>', function()
    M.confirm_selection()
  end, opts)

  vim.keymap.set('n', 'q', function()
    M.close()
  end, opts)

  vim.keymap.set('n', '<Esc>', function()
    M.close()
  end, opts)

  vim.keymap.set('n', 'o', function()
    M.toggle_options_mode()
  end, opts)

  vim.keymap.set('n', 'i', function()
    if not M.options_mode then
      M.options_mode = true
      M._options_diagram_cache = nil
    end
    M.handle_diff_toggle(M.float_win, options.cycle_ignore_whitespace)
  end, opts)

  vim.keymap.set('n', 'h', function()
    if not M.options_mode then
      M.options_mode = true
      M._options_diagram_cache = nil
    end
    M.handle_diff_toggle(M.float_win, options.toggle_indent_heuristic)
  end, opts)

  vim.keymap.set('n', 'a', function()
    if not M.options_mode then
      M.options_mode = true
      M._options_diagram_cache = nil
    end
    M.handle_diff_toggle(M.float_win, options.cycle_diff_algorithm)
  end, opts)

  vim.keymap.set('n', 'd', function()
    if not M.options_mode then
      M.toggle_options_mode()
    end
    options.cycle_conflict_style()
    M.refresh()
  end, opts)

  vim.keymap.set('n', 'f', function()
    if not M.options_mode then
      M.toggle_options_mode()
    end
    options.cycle_favor()
    M.refresh()
  end, opts)

  vim.keymap.set('n', 'm', function()
    if not M.options_mode then
      M.toggle_options_mode()
    end
    options.cycle_merge_algorithm()
    M.refresh()
  end, opts)

  vim.keymap.set('n', 'r', function()
    if not M.options_mode then
      M.toggle_options_mode()
    end
    if options.recompute(false) then
      M.refresh()
    else
      M.refresh()
    end
  end, opts)
end

function M.setup_autocmds()
  if M.autocmd_group then
    pcall(vim.api.nvim_del_augroup_by_name, 'MergeToolHelp')
  end

  M.autocmd_group = vim.api.nvim_create_augroup('MergeToolHelp', { clear = true })

  vim.api.nvim_create_autocmd({ 'WinEnter', 'VimResized' }, {
    group = M.autocmd_group,
    callback = function(ev)
      if not M.is_open() or M._in_toggle then
        return
      end
      if ev.event == 'VimResized' then
        M._options_diagram_cache = nil
      end
      if ev.event == 'WinEnter' then
        local win = ev.win
        if win and win ~= M.float_win and vim.api.nvim_win_is_valid(win) then
          M.tracked_win = win
        end
      end
      if vim.api.nvim_get_current_win() ~= M.float_win then
        -- refresh shading when user moves in merge windows
      end
      M.refresh()
    end,
  })
end

function M.open()
  if not detect.is_session() then
    vim.notify('merge-tool-help: not in a merge/diff session', vim.log.levels.WARN)
    return
  end

  detect.ensure_output_bufnr()
  options.sync_from_diffopt()

  if M.is_open() then
    M.refresh()
    vim.api.nvim_set_current_win(M.float_win)
    return
  end

  local current = vim.api.nvim_get_current_win()
  if current ~= M.float_win then
    M.tracked_win = current
  end

  M.float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(M.float_buf, 'merge-tool-help')
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = M.float_buf })
  vim.api.nvim_set_option_value('filetype', 'merge-tool-help', { buf = M.float_buf })

  local width = math.min(M.config.width, vim.o.columns - 4)
  M.float_win = vim.api.nvim_open_win(M.float_buf, true, {
    relative = 'editor',
    width = width,
    height = 12,
    row = math.floor((vim.o.lines - 12) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    noautocmd = true,
    focusable = true,
  })

  vim.api.nvim_win_set_option(M.float_win, 'winhighlight', 'Normal:Normal,FloatBorder:MergeToolHelpBorder')

  M.options_mode = false
  M.bind_diffupdate_hooks()
  M.setup_keymaps()
  M.setup_autocmds()
  M.refresh()
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

---@param cfg MergeToolHelpConfig|nil
function M.setup(cfg)
  if cfg then
    M.config = vim.tbl_deep_extend('force', M.config, cfg)
  end
end

return M
