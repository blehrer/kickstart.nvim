local M = {}

M.wide = { signcolumn = 'yes:4', numberwidth = 4 }

local group = vim.api.nvim_create_augroup('kickstart.gutter', { clear = true })

local function max_line_digits(buf, win)
  buf = buf or vim.api.nvim_get_current_buf()
  win = win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
    return 1
  end
  local count = vim.api.nvim_buf_line_count(buf)
  local cursor = vim.api.nvim_win_get_cursor(win)[1]
  local max_num = math.max(count, cursor - 1, count - cursor)
  return #tostring(max_num)
end

function M.tight_numberwidth(buf, win)
  return math.min(6, max_line_digits(buf, win) + 1)
end

function M.is_wide()
  return vim.o.signcolumn == M.wide.signcolumn and vim.o.numberwidth == M.wide.numberwidth
end

function M.apply_wide()
  vim.o.signcolumn = M.wide.signcolumn
  vim.o.numberwidth = M.wide.numberwidth
end

function M.max_tight_numberwidth()
  local ui = require('config.ui_toggle')
  local max_width = 2
  for _, win in ipairs(ui.target_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    max_width = math.max(max_width, M.tight_numberwidth(buf, win))
  end
  return max_width
end

function M.apply_tight()
  vim.o.signcolumn = 'auto'
  vim.o.numberwidth = M.max_tight_numberwidth()
end

function M.refresh_tight()
  if M.is_wide() then
    return
  end
  vim.o.numberwidth = M.max_tight_numberwidth()
end

function M.setup_toggle()
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'CursorMoved' }, {
    group = group,
    callback = function()
      M.refresh_tight()
    end,
  })

  Snacks.toggle({
    name = 'Wide gutter',
    id = 'gutter_width',
    get = M.is_wide,
    set = function(state)
      if state then
        M.apply_wide()
      else
        M.apply_tight()
      end
    end,
  }):map('<leader>ug')
end

return M
