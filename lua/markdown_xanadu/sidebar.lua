local config = require('markdown_xanadu.config')
local registry = require('markdown_xanadu.registry')
local viewport = require('markdown_xanadu.viewport')

local M = {}

local ns = vim.api.nvim_create_namespace('markdown_xanadu.sidebar')

local state = {
  main_win = nil,
  sidebar_win = nil,
  sidebar_buf = nil,
  cursor_line = 1,
  selected = 1,
  augroup = vim.api.nvim_create_augroup('markdown_xanadu.sidebar', { clear = true }),
}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

---@param entry markdown_xanadu.Entry
---@return string
local function format_row(entry)
  local icon = entry.link.kind == 'embed' and '⊞ ' or '→ '
  local status = entry.open and '[open]' or '[    ]'
  local line = entry.link.range[1] + 1
  return ('%s%s L%d %s'):format(icon, status, line, entry.label)
end

local function sync_selected_from_sidebar()
  if not valid_win(state.sidebar_win) then
    return
  end
  local row = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
  if row >= 3 then
    state.selected = row - 2
  end
end

---@param bufnr integer
local function render(bufnr)
  if not state.sidebar_buf or not vim.api.nvim_buf_is_valid(state.sidebar_buf) then
    return
  end
  local entries = registry.get(bufnr)
  local lines = { 'Transclusions (' .. #entries .. ')', '' }
  for i, entry in ipairs(entries) do
    lines[#lines + 1] = format_row(entry)
  end
  if #entries == 0 then
    lines[#lines + 1] = '(none)'
  end
  vim.bo[state.sidebar_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.sidebar_buf, 0, -1, false, lines)
  vim.bo[state.sidebar_buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(state.sidebar_buf, ns, 0, -1)
  if state.selected >= 1 and state.selected <= #entries then
    vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, 'Visual', state.selected + 2, 0, -1)
  end
  if config.get().follow and state.main_win and valid_win(state.main_win) then
    local row = vim.api.nvim_win_get_cursor(state.main_win)[1]
    state.cursor_line = row
    for i, entry in ipairs(entries) do
      if entry.link.range[1] + 1 == row then
        local hl_row = i + 1
        vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, 'CursorLine', hl_row, 0, -1)
        state.selected = i
      end
    end
  end
end

---@param bufnr integer
local function debounced_scan(bufnr)
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      registry.scan(bufnr)
      render(bufnr)
    end
  end, 200)
end

function M.is_open()
  return valid_win(state.sidebar_win)
end

function M.close()
  vim.api.nvim_clear_autocmds({ group = state.augroup })
  if valid_win(state.sidebar_win) then
    vim.api.nvim_win_close(state.sidebar_win, true)
  end
  state.sidebar_win = nil
  state.main_win = nil
end

---@param main_win integer
function M.open(main_win)
  M.close()
  main_win = main_win or vim.api.nvim_get_current_win()
  local main_buf = vim.api.nvim_win_get_buf(main_win)
  state.main_win = main_win

  if not state.sidebar_buf or not vim.api.nvim_buf_is_valid(state.sidebar_buf) then
    state.sidebar_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.sidebar_buf].bufhidden = 'hide'
    vim.bo[state.sidebar_buf].buftype = 'nofile'
    vim.bo[state.sidebar_buf].swapfile = false
    vim.api.nvim_buf_set_name(state.sidebar_buf, 'xanadu://links')
  end

  registry.scan(main_buf)

  vim.api.nvim_win_call(main_win, function()
    local cfg = config.get()
    local width = math.max(20, math.floor(vim.api.nvim_win_get_width(0) * cfg.sidebar_width))
    vim.cmd('vertical rightbelow ' .. width .. 'split')
    state.sidebar_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.sidebar_win, state.sidebar_buf)
    vim.wo[state.sidebar_win].number = false
    vim.wo[state.sidebar_win].relativenumber = false
    vim.wo[state.sidebar_win].wrap = false
    vim.wo[state.sidebar_win].winfixwidth = true
  end)

  render(main_buf)
  vim.api.nvim_set_current_win(main_win)

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufEnter' }, {
    group = state.augroup,
    buffer = main_buf,
    callback = function()
      render(main_buf)
    end,
  })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'BufWritePost' }, {
    group = state.augroup,
    buffer = main_buf,
    callback = function()
      debounced_scan(main_buf)
    end,
  })

  vim.keymap.set('n', '<CR>', function()
    sync_selected_from_sidebar()
    M.toggle_selected()
  end, { buffer = state.sidebar_buf, desc = 'Toggle transclusion open' })

  vim.keymap.set('n', 'x', function()
    sync_selected_from_sidebar()
    M.close_selected()
  end, { buffer = state.sidebar_buf, desc = 'Close transclusion embed' })

  vim.keymap.set('n', 'o', function()
    sync_selected_from_sidebar()
    M.goto_selected()
  end, { buffer = state.sidebar_buf, desc = 'Go to transclusion line' })

  vim.keymap.set('n', 'j', function()
    vim.cmd('normal! j')
    sync_selected_from_sidebar()
    render(main_buf)
  end, { buffer = state.sidebar_buf, desc = 'Next transclusion' })

  vim.keymap.set('n', 'k', function()
    vim.cmd('normal! k')
    sync_selected_from_sidebar()
    render(main_buf)
  end, { buffer = state.sidebar_buf, desc = 'Previous transclusion' })

  vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
    group = state.augroup,
    buffer = state.sidebar_buf,
    callback = function()
      sync_selected_from_sidebar()
      render(main_buf)
    end,
  })
end

function M.goto_selected()
  if not state.main_win or not valid_win(state.main_win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(state.main_win)
  local entries = registry.get(buf)
  local entry = entries[state.selected]
  if not entry then
    return
  end
  vim.api.nvim_set_current_win(state.main_win)
  vim.api.nvim_win_set_cursor(state.main_win, { entry.link.range[1] + 1, entry.link.range[2] })
end

function M.toggle_selected()
  if not state.main_win or not valid_win(state.main_win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(state.main_win)
  local entries = registry.get(buf)
  local entry = entries[state.selected]
  if not entry then
    return
  end
  viewport.toggle(state.main_win, entry)
  render(buf)
  viewport.refresh_gutter(state.main_win)
end

function M.close_selected()
  if not state.main_win or not valid_win(state.main_win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(state.main_win)
  local entries = registry.get(buf)
  local entry = entries[state.selected]
  if not entry then
    return
  end
  viewport.close(state.main_win, entry)
  render(buf)
  viewport.refresh_gutter(state.main_win)
end

---@param main_win integer
function M.refresh(main_win)
  if not M.is_open() then
    return
  end
  local buf = vim.api.nvim_win_get_buf(main_win)
  render(buf)
end

return M
