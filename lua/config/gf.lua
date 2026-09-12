local M = {}

-- ponytail: sequential path retry; ceiling is 4 bases, upgrade = includeexpr/path hooks
local function git_toplevel(dir)
  if not dir or dir == '' then
    return nil
  end
  local out = vim.fn.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.fn.fnamemodify(vim.trim(out), ':p')
end

---@return string[]
function M.search_bases()
  local bases, seen = {}, {}
  local function add(dir)
    if not dir or dir == '' then
      return
    end
    dir = vim.fn.fnamemodify(dir, ':p'):gsub('/$', '')
    if not seen[dir] then
      seen[dir] = true
      bases[#bases + 1] = dir
    end
  end

  add(vim.loop.cwd())
  local buf = vim.api.nvim_buf_get_name(0)
  if buf ~= '' then
    local buf_dir = vim.fn.fnamemodify(buf, ':h')
    add(buf_dir)
    add(git_toplevel(buf_dir))
  end
  add(git_toplevel(vim.loop.cwd()))
  return bases
end

---@param normal_cmd string
function M.goto_file(normal_cmd)
  local orig_path = vim.o.path
  for _, dir in ipairs(M.search_bases()) do
    vim.o.path = dir .. ',,'
    vim.v.errmsg = ''
    vim.cmd('keepjumps silent! normal! ' .. normal_cmd)
    if vim.v.errmsg == '' then
      vim.o.path = orig_path
      return
    end
  end
  vim.o.path = orig_path
  vim.cmd('normal! ' .. normal_cmd)
end

return M
