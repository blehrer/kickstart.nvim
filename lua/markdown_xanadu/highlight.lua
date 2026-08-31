local parse = require('markdown_xanadu.parse')
local registry = require('markdown_xanadu.registry')
local focus = require('markdown_xanadu.focus')

local M = {}

local ns = vim.api.nvim_create_namespace('markdown_xanadu.highlight')

---@param bufnr integer
function M.clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

---@param bufnr integer
---@param main_win? integer
function M.refresh(bufnr, main_win)
  M.clear(bufnr)
  if #registry.open_entries(bufnr) == 0 then
    return
  end

  main_win = main_win or vim.g.markdown_xanadu_main_win
  if not (main_win and vim.api.nvim_win_is_valid(main_win)) then
    return
  end

  local active = focus.active_entry(bufnr, main_win)
  for _, entry in ipairs(registry.open_entries(bufnr)) do
    local sr, sc, _, ec = entry.link.range[1], entry.link.range[2], entry.link.range[3], entry.link.range[4]
    local hl = (active and active.id == entry.id) and 'MarkdownXanaduLinkActive' or 'MarkdownXanaduLinkOpen'
    vim.api.nvim_buf_add_highlight(bufnr, ns, hl, sr, sc, ec)
  end
end

---@param bufnr integer
function M.apply(bufnr)
  M.clear(bufnr)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local link = parse.link_at_cursor(bufnr, row - 1, col - 1)
  if not link then
    return
  end
  local sr, sc, _, ec = link.range[1], link.range[2], link.range[3], link.range[4]
  vim.api.nvim_buf_add_highlight(bufnr, ns, 'LspReferenceRead', sr, sc, ec)
end

---@param bufnr integer
function M.setup(bufnr)
  local group = vim.api.nvim_create_augroup('markdown_xanadu.highlight.' .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    group = group,
    buffer = bufnr,
    callback = function()
      if #registry.open_entries(bufnr) > 0 then
        return
      end
      M.apply(bufnr)
    end,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = group,
    buffer = bufnr,
    callback = function()
      if #registry.open_entries(bufnr) > 0 then
        M.refresh(bufnr)
      else
        M.clear(bufnr)
      end
    end,
  })
  vim.api.nvim_create_autocmd('BufLeave', {
    group = group,
    buffer = bufnr,
    callback = function()
      M.clear(bufnr)
    end,
  })
end

return M
