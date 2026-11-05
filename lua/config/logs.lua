local M = {}

M.MAX_BYTES = 1024 * 1024 -- 1 MiB
M.KEEP_BYTES = 256 * 1024 -- 256 KiB

-- Known active log files in stdpath('log'). Any other *.log is from a removed plugin and is pruned.
M.KNOWN_LOGS = {
  ['conform.log'] = true,
  ['dap.log'] = true,
  ['lsp.log'] = true,
  ['mason.log'] = true,
  ['neotest.log'] = true,
  ['nio.log'] = true,
  ['nvim.log'] = true,
}

--- Truncate a log file in-place to the last `keep_bytes` (aligned to next newline) when it exceeds `max_bytes`.
---@param path string
---@param max_bytes? integer
---@param keep_bytes? integer
---@return boolean truncated
function M.truncate_file(path, max_bytes, keep_bytes)
  max_bytes = max_bytes or M.MAX_BYTES
  keep_bytes = keep_bytes or M.KEEP_BYTES

  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= 'file' or stat.size <= max_bytes then
    return false
  end

  local fd = vim.uv.fs_open(path, 'r', 420)
  if not fd then
    return false
  end

  local offset = math.max(0, stat.size - keep_bytes)
  local tail = vim.uv.fs_read(fd, stat.size - offset, offset)
  vim.uv.fs_close(fd)
  if not tail then
    return false
  end

  if offset > 0 then
    local nl = tail:find('\n', 1, true)
    if nl then
      tail = tail:sub(nl + 1)
    end
  end

  -- ponytail: atomic temp-file swap in same directory avoids partial writes if two instances race
  local tmp = path .. '.tmp.' .. tostring(vim.fn.getpid())
  local wfd = vim.uv.fs_open(tmp, 'w', 420)
  if not wfd then
    return false
  end
  vim.uv.fs_write(wfd, tail, 0)
  vim.uv.fs_close(wfd)
  vim.uv.fs_rename(tmp, path)
  return true
end

--- Sweep `dir` (defaults to `stdpath('log')`): remove unknown `*.log` files and cap known logs.
---@param dir? string
---@param opts? { max_bytes?: integer, keep_bytes?: integer, known?: table<string, boolean> }
---@return { pruned: string[], truncated: string[] }
function M.maintain(dir, opts)
  dir = dir or vim.fn.stdpath('log')
  opts = opts or {}
  local known = opts.known or M.KNOWN_LOGS
  local max_bytes = opts.max_bytes or M.MAX_BYTES
  local keep_bytes = opts.keep_bytes or M.KEEP_BYTES

  local result = { pruned = {}, truncated = {} }
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return result
  end

  while true do
    local name, ftype = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if ftype == 'file' and name:match('%.log$') then
      local full = dir .. '/' .. name
      if not known[name] then
        if vim.uv.fs_unlink(full) then
          table.insert(result.pruned, name)
        end
      elseif M.truncate_file(full, max_bytes, keep_bytes) then
        table.insert(result.truncated, name)
      end
    end
  end

  return result
end

function M.setup()
  vim.schedule(function()
    M.maintain()
  end)
end

return M
