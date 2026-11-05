--- Focus any newly opened focusable window after running a pane toggle action.
local M = {}

local function focusable_wins()
  local wins = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w).focusable ~= false then
      wins[w] = true
    end
  end
  return wins
end

local function focus_new(before)
  for w in pairs(focusable_wins()) do
    if not before[w] and vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_set_current_win(w)
      return true
    end
  end
  return false
end

---@param fn fun()|string function or Ex command string
---@return fun()
function M.toggle(fn)
  return function()
    local before = focusable_wins()
    if type(fn) == 'string' then
      vim.cmd(fn)
    else
      fn()
    end
    if not focus_new(before) then
      vim.schedule(function()
        focus_new(before)
      end)
    end
  end
end

return M
