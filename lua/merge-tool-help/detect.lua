local M = {}

local ROLES = { 'LOCAL', 'BASE', 'REMOTE', 'MERGED' }

---@type number|nil git mergetool output buffer ($MERGED), captured once per session
M.output_bufnr = nil

---@param path string|nil
---@return string
local function normalize_path(path)
  if not path or path == '' then
    return ''
  end
  return vim.fn.resolve(vim.fn.fnamemodify(path, ':p'))
end

---@return table<string, string>
local function env_paths()
  local paths = {}
  for _, role in ipairs(ROLES) do
    local value = vim.env[role]
    if value and value ~= '' then
      paths[role] = normalize_path(value)
    end
  end
  return paths
end

--- Capture and remember the mergetool output buffer from $MERGED.
---@return number|nil
function M.ensure_output_bufnr()
  if M.output_bufnr and vim.api.nvim_buf_is_valid(M.output_bufnr) then
    return M.output_bufnr
  end

  local merged = vim.env.MERGED
  if not merged or merged == '' then
    return nil
  end

  local path = normalize_path(merged)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      if normalize_path(vim.api.nvim_buf_get_name(buf)) == path then
        M.output_bufnr = buf
        return buf
      end
    end
  end

  return nil
end

---@param bufnr number
---@return boolean
function M.is_output_buf(bufnr)
  local output = M.ensure_output_bufnr()
  return output ~= nil and bufnr == output
end

---@param bufnr number
---@return string
function M.role_of_buf(bufnr)
  if M.is_output_buf(bufnr) then
    return 'MERGED'
  end

  local name = normalize_path(vim.api.nvim_buf_get_name(bufnr))
  if name == '' then
    return 'UNKNOWN'
  end

  for role, path in pairs(env_paths()) do
    if name == path then
      return role
    end
  end

  local upper_name = name:upper()
  for _, role in ipairs(ROLES) do
    if upper_name:find('/' .. role, 1, true) or vim.fn.fnamemodify(name, ':t'):upper():find(role, 1, true) then
      return role
    end
  end

  return 'UNKNOWN'
end

---@return boolean
function M.is_session()
  if vim.env.MERGED and vim.env.MERGED ~= '' then
    return true
  end

  local diff_wins = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.wo[win].diff then
      diff_wins = diff_wins + 1
      if diff_wins >= 2 then
        return true
      end
    end
  end

  return false
end

---@param bufnr number
---@return boolean
function M.is_editable(bufnr)
  if M.is_output_buf(bufnr) then
    return true
  end

  local role = M.role_of_buf(bufnr)
  if role == 'MERGED' then
    return true
  end
  if role ~= 'UNKNOWN' then
    return false
  end
  return vim.bo[bufnr].modifiable
end

---@return string|nil
function M.merged_bufname()
  local merged = vim.env.MERGED
  if merged and merged ~= '' then
    return normalize_path(merged)
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if M.role_of_buf(buf) == 'MERGED' then
      return normalize_path(vim.api.nvim_buf_get_name(buf))
    end
  end
  return nil
end

---@return number|nil
function M.merged_bufnr()
  local merged_path = M.merged_bufname()
  if not merged_path then
    return nil
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = normalize_path(vim.api.nvim_buf_get_name(buf))
      if name == merged_path then
        return buf
      end
    end
  end
  return nil
end

---@param bufnr number
---@return boolean
function M.has_conflict_markers(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for _, line in ipairs(lines) do
    if line:match('^<<<<<<<') or line:match('^=======$') or line:match('^>>>>>>>') then
      return true
    end
  end
  return false
end

---@param role string
---@return table<string, string>
function M.role_info(role)
  local info = {
    LOCAL = {
      edit = 'NO',
      why = 'Your branch version — reference while resolving. Copy into MERGED.',
    },
    BASE = {
      edit = 'NO',
      why = 'Common ancestor — reference only. Copy ideas into MERGED, never edit BASE.',
    },
    REMOTE = {
      edit = 'NO',
      why = 'Incoming branch — reference only. Copy into MERGED.',
    },
    MERGED = {
      edit = 'YES',
      why = 'Output file — resolve conflicts here, then :wq to finish.',
    },
    UNKNOWN = {
      edit = 'MAYBE',
      why = 'Unknown role — edit only if modifiable and you know this is the output buffer.',
    },
  }
  return info[role] or info.UNKNOWN
end

return M
