--- Snacks gitbrowse: copy remote file URL to clipboard (+ and *).
local M = {}

local PROMPT = 'Select remote to browse'
local COPY_NOTIFY_MS = 2000

---@param url string
local function copy_to_clipboard(url)
  vim.fn.setreg('+', url, 'c')
  vim.fn.setreg('*', url, 'c')
end

---@param start string
---@return string?
local function git_toplevel(start)
  if start == '' then
    start = vim.fn.getcwd()
  end
  local out = vim.fn.systemlist({ 'git', '-C', start, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error == 0 and out[1] and out[1] ~= '' then
    return out[1]
  end
end

---@param git_dir string
---@param items { name: string, url: string }[]
---@return { name: string, url: string }?
function M.pick_remote(git_dir, items)
  if #items <= 1 then
    return items[1]
  end

  local by_name = {}
  for _, r in ipairs(items) do
    by_name[r.name] = r
  end

  local branch = vim.fn.systemlist({ 'git', '-C', git_dir, 'rev-parse', '--abbrev-ref', 'HEAD' })[1]
  if branch and branch ~= 'HEAD' then
    local tracking =
      vim.fn.systemlist({ 'git', '-C', git_dir, 'config', '--get', ('branch.%s.remote'):format(branch) })[1]
    if tracking and tracking ~= '' and by_name[tracking] then
      return by_name[tracking]
    end
  end

  local by_url = {}
  for _, r in ipairs(items) do
    by_url[r.url] = by_url[r.url] or r
  end
  local unique = vim.tbl_values(by_url)
  if #unique == 1 then
    return unique[1]
  end

  for _, name in ipairs({ 'origin', 'upstream' }) do
    if by_name[name] then
      return by_name[name]
    end
  end

  return nil
end

---@param opts? snacks.gitbrowse.Config
function M.open(opts)
  opts = vim.tbl_extend('force', {
    notify = false,
    open = function(url)
      copy_to_clipboard(url)
      vim.notify('Remote URL copied to clipboard', vim.log.levels.INFO, {
        title = 'Git Browse',
        timeout = COPY_NOTIFY_MS,
      })
    end,
  }, opts or {})

  local file = vim.api.nvim_buf_get_name(0)
  local start = (file ~= '' and vim.fn.fnamemodify(file, ':h')) or vim.fn.getcwd()
  local git_dir = git_toplevel(start)

  local ui_select = vim.ui.select
  vim.ui.select = function(items, spec, on_choice)
    if spec and spec.prompt == PROMPT and type(items) == 'table' and git_dir then
      local picked = M.pick_remote(git_dir, items)
      if picked then
        return on_choice(picked)
      end
    end
    return ui_select(items, spec, on_choice)
  end

  local ok, err = pcall(require('snacks.gitbrowse').open, opts)
  vim.ui.select = ui_select

  if not ok and err ~= '__ignore__' then
    error(err)
  end
end

return M
