local config = require('markdown_xanadu.config')
local focus = require('markdown_xanadu.focus')
local registry = require('markdown_xanadu.registry')
local gutter = require('markdown_xanadu.gutter')

local M = {}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

---@param bufnr integer
---@return integer?
local function stack_bottom(bufnr)
  local open = registry.open_entries(bufnr)
  for i = #open, 1, -1 do
    if open[i].embed_win and valid_win(open[i].embed_win) then
      return open[i].embed_win
    end
  end
  return nil
end

---@param embed_win integer
---@param resolved { file: string, line: integer, col: integer }
local function load_embed(embed_win, resolved)
  vim.cmd('edit ' .. vim.fn.fnameescape(resolved.file))
  vim.api.nvim_win_set_cursor(embed_win, { resolved.line, resolved.col })
  vim.wo[embed_win].wrap = false
  vim.wo[embed_win].number = true
end

---@param main_win integer
---@param entry markdown_xanadu.Entry
function M.open(main_win, entry)
  if not entry.resolved or not entry.resolved.exists then
    vim.notify('Transclusion target not found: ' .. entry.label, vim.log.levels.WARN)
    return
  end

  vim.g.markdown_xanadu_main_win = main_win

  local cfg = config.get()
  local buf = vim.api.nvim_win_get_buf(main_win)
  local open = registry.open_entries(buf)

  if entry.embed_win and valid_win(entry.embed_win) then
    vim.api.nvim_set_current_win(main_win)
    M.refresh_gutter(main_win)
    pcall(require('markdown_xanadu.highlight').refresh, buf, main_win)
    return
  end

  if #open >= cfg.max_open_embeds then
    local oldest = open[1]
    if oldest.embed_win and valid_win(oldest.embed_win) then
      vim.api.nvim_win_close(oldest.embed_win, true)
    end
    registry.set_open(buf, oldest, false, nil)
  end

  local resolved = entry.resolved
  local bottom = stack_bottom(buf)

  if not bottom then
    vim.api.nvim_win_call(main_win, function()
      local width = math.max(20, math.floor(vim.api.nvim_win_get_width(main_win) * cfg.embed_width))
      vim.cmd('vertical rightbelow ' .. width .. 'split')
      local embed_win = vim.api.nvim_get_current_win()
      load_embed(embed_win, resolved)
      registry.set_open(buf, entry, true, embed_win)
      vim.api.nvim_set_current_win(main_win)
    end)
  else
    vim.api.nvim_win_call(bottom, function()
      vim.cmd('horizontal belowright split')
      local embed_win = vim.api.nvim_get_current_win()
      load_embed(embed_win, resolved)
      registry.set_open(buf, entry, true, embed_win)
      vim.api.nvim_set_current_win(main_win)
    end)
  end

  M.refresh_gutter(main_win)
  pcall(require('markdown_xanadu.highlight').refresh, buf, main_win)
end

---@param main_win integer
---@param entry markdown_xanadu.Entry
function M.close(main_win, entry)
  if entry.embed_win and valid_win(entry.embed_win) then
    vim.api.nvim_win_close(entry.embed_win, true)
  end
  local buf = vim.api.nvim_win_get_buf(main_win)
  registry.set_open(buf, entry, false, nil)
  M.refresh_gutter(main_win)
  pcall(require('markdown_xanadu.highlight').refresh, buf, main_win)
end

---@param main_win integer
---@param entry markdown_xanadu.Entry
function M.toggle(main_win, entry)
  if entry.open then
    M.close(main_win, entry)
  else
    M.open(main_win, entry)
  end
end

---@param main_win integer
function M.refresh_gutter(main_win)
  if not valid_win(main_win) then
    gutter.close()
    return
  end
  local buf = vim.api.nvim_win_get_buf(main_win)
  local active_id = focus.active_id(buf, main_win)
  local pairs = {}
  for _, entry in ipairs(registry.open_entries(buf)) do
    if entry.embed_win and valid_win(entry.embed_win) and entry.resolved then
      pairs[#pairs + 1] = {
        id = entry.id,
        left_win = main_win,
        right_win = entry.embed_win,
        left_line = entry.link.range[1] + 1,
        right_line = entry.resolved.line,
      }
    end
  end
  if #pairs == 0 then
    gutter.close()
    return
  end
  gutter.schedule(main_win, pairs, active_id)
end

---@param main_win integer
---@param jump? boolean
function M.go_to(main_win, jump)
  local parse = require('markdown_xanadu.parse')
  local buf = vim.api.nvim_win_get_buf(main_win)
  local row, col = unpack(vim.api.nvim_win_get_cursor(main_win))
  local link = parse.link_at_cursor(buf, row - 1, col - 1)
  if not link then
    return false
  end
  local entry = registry.entry_at_line(buf, row)
  if not entry then
    registry.scan(buf)
    entry = registry.entry_at_line(buf, row)
  end
  if not entry or not entry.resolved or not entry.resolved.exists then
    vim.notify('Transclusion target not found', vim.log.levels.WARN)
    return true
  end
  if jump then
    vim.cmd('edit ' .. vim.fn.fnameescape(entry.resolved.file))
    vim.api.nvim_win_set_cursor(0, { entry.resolved.line, entry.resolved.col })
  end
  return true
end

function M.close_all(main_win)
  if not valid_win(main_win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(main_win)
  for _, entry in ipairs(vim.list_extend({}, registry.open_entries(buf))) do
    M.close(main_win, entry)
  end
  gutter.close()
end

return M
