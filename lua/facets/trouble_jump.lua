local Preview = require('trouble.view.preview')

local M = {}

---@type string|nil git root for relative paths from facet runners
M.root = nil

---@type { win: number, buf: number, filename: string }|nil
M.origin = nil

---@param root string|nil
function M.capture_origin(root)
  M.root = root
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' then
    return
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return
  end
  M.origin = {
    win = win,
    buf = buf,
    filename = vim.fs.normalize(name),
  }
end

---@param filename string
---@param root? string
---@return string
function M.normalize_filename(filename, root)
  filename = vim.fs.normalize(filename)
  if vim.uv.fs_stat(filename) then
    return filename
  end
  if root then
    local abs = vim.fs.normalize(vim.fs.joinpath(root, filename))
    if vim.uv.fs_stat(abs) then
      return abs
    end
  end
  return filename
end

local function valid_edit_win(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return false
  end
  if Preview.is_win(win) or vim.w[win].trouble then
    return false
  end
  if vim.api.nvim_win_get_config(win).relative ~= '' then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == ''
end

---@param view trouble.View
---@return number|nil
function M.target_win(view)
  if M.origin and valid_edit_win(M.origin.win) then
    return M.origin.win
  end
  local main = view:main()
  if main and valid_edit_win(main.win) then
    return main.win
  end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if valid_edit_win(w) then
      return w
    end
  end
  return nil
end

---@param ctx trouble.Action.ctx
---@return trouble.Item|nil
local function resolve_item(ctx)
  if ctx.item then
    return ctx.item
  end
  local node = ctx.node
  if not node then
    return nil
  end
  if node.item and not node.group then
    return node.item
  end
  local function first_leaf(n)
    if n.item and not n.group then
      return n.item
    end
    for _, child in ipairs(n.children or {}) do
      local item = first_leaf(child)
      if item then
        return item
      end
    end
  end
  return first_leaf(node)
end

---@param path string
---@return number
local function buf_for_path(path)
  path = M.normalize_filename(path, M.root)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= '' and vim.fs.normalize(name) == path then
        return buf
      end
    end
  end
  local buf = vim.fn.bufadd(path)
  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
  end
  if not vim.bo[buf].buflisted then
    vim.bo[buf].buflisted = true
  end
  return buf
end

---@param view trouble.View
---@param ctx trouble.Action.ctx
---@param opts? { close?: boolean }
function M.jump(view, ctx, opts)
  opts = opts or {}
  local item = resolve_item(ctx)
  if not item then
    if ctx.node then
      view:fold(ctx.node)
    end
    return
  end

  vim.schedule(function()
    Preview.close()
  end)

  if not item.filename then
    return
  end

  local win = M.target_win(view)
  if not win then
    vim.cmd('split')
    win = vim.api.nvim_get_current_win()
  end

  local buf = buf_for_path(item.filename)
  item.buf = buf

  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! m'")
  end)

  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, item.pos)
  vim.api.nvim_win_call(win, function()
    vim.cmd('norm! zzzv')
  end)

  if opts.close then
    view:close()
  end
end

function M.action_jump(view, ctx)
  M.jump(view, ctx)
end

function M.action_jump_close(view, ctx)
  M.jump(view, ctx, { close = true })
end

--- Key overrides for facet Trouble modes (jump to invoke window, not preview/main guess).
function M.keys()
  return {
    ['<cr>'] = { action = M.action_jump, desc = 'Jump to item' },
    ['<2-leftmouse>'] = { action = M.action_jump, desc = 'Jump to item' },
    o = { action = M.action_jump_close, desc = 'Jump and close' },
  }
end

return M
