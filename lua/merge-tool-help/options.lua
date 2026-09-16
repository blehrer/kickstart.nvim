local detect = require('merge-tool-help.detect')

local M = {}

---@class MergeToolOptionsState
---@field ignore_whitespace number
---@field indent_heuristic boolean
---@field diff_algorithm number
---@field conflict_style number
---@field favor number
---@field merge_algorithm number
---@field last_error string|nil

local IGNORE_CYCLE = { 'off', 'iwhite', 'iwhiteall', 'iwhiteeol' }
local DIFF_ALGO_CYCLE = { 'myers', 'minimal', 'patience', 'histogram' }
local CONFLICT_STYLE_CYCLE = { 'default', 'diff3', 'zdiff3' }
local FAVOR_CYCLE = { 'none', 'ours', 'theirs', 'union' }
local MERGE_ALGO_CYCLE = { 'myers', 'minimal', 'patience', 'histogram' }

M.state = {
  ignore_whitespace = 1,
  indent_heuristic = false,
  diff_algorithm = 1,
  conflict_style = 1,
  favor = 1,
  merge_algorithm = 1,
  last_error = nil,
}

---@return string[]
local function parse_diffopt()
  return vim.split(vim.o.diffopt, ',', { plain = true })
end

---@param part string
---@return boolean
local function is_managed_diffopt(part)
  if part == 'iwhite' or part == 'iwhiteall' or part == 'iwhiteeol' or part == 'indent-heuristic' then
    return true
  end
  if part:match('^algorithm:') then
    return true
  end
  return false
end

---@param current number
---@param cycle string[]
---@return number
local function cycle_index(current, cycle)
  local index = tonumber(current) or 1
  index = index + 1
  if index > #cycle then
    index = 1
  end
  return index
end

---@return string
local function ignore_label()
  return IGNORE_CYCLE[M.state.ignore_whitespace] or IGNORE_CYCLE[1]
end

--- Sync ignore-whitespace index from the live global diffopt.
function M.sync_from_diffopt()
  local mode = 1
  for _, part in ipairs(parse_diffopt()) do
    if part == 'iwhiteeol' then
      mode = 4
    elseif part == 'iwhiteall' then
      mode = 3
    elseif part == 'iwhite' then
      mode = 2
    end
  end
  M.state.ignore_whitespace = mode
end

---@return string
function M.build_diffopt()
  local parts = {}
  for _, part in ipairs(parse_diffopt()) do
    if not is_managed_diffopt(part) then
      table.insert(parts, part)
    end
  end

  local ignore = ignore_label()
  if ignore ~= 'off' then
    table.insert(parts, ignore)
  end
  if M.state.indent_heuristic then
    table.insert(parts, 'indent-heuristic')
  end
  local algo = DIFF_ALGO_CYCLE[M.state.diff_algorithm]
  table.insert(parts, 'algorithm:' .. algo)

  return table.concat(parts, ',')
end

---@param _exclude_win_id number|nil
function M.apply_diffopt(_exclude_win_id)
  vim.o.diffopt = M.build_diffopt()
  M.schedule_diffupdate()
  M.state.last_error = nil
end

local diffupdate_timer ---@type number|nil
local diffupdate_pending = false

M.on_diffupdate_start = nil ---@type fun()|nil
M.on_diffupdate_done = nil ---@type fun()|nil

--- ponytail: coalesce rapid diffopt toggles; one diffupdate after keys stop
function M.schedule_diffupdate()
  if diffupdate_timer then
    vim.fn.timer_stop(diffupdate_timer)
  end
  if not diffupdate_pending then
    diffupdate_pending = true
    if M.on_diffupdate_start then
      M.on_diffupdate_start()
    end
  end
  diffupdate_timer = vim.fn.timer_start(75, function()
    diffupdate_timer = nil
    diffupdate_pending = false
    if not pcall(vim.cmd, 'diffupdate') then
      M.state.last_error = 'diffupdate failed'
    end
    if M.on_diffupdate_done then
      M.on_diffupdate_done()
    end
  end)
end

function M.cancel_diffupdate()
  if diffupdate_timer then
    vim.fn.timer_stop(diffupdate_timer)
    diffupdate_timer = nil
  end
  if diffupdate_pending then
    diffupdate_pending = false
    if M.on_diffupdate_done then
      M.on_diffupdate_done()
    end
  end
end

function M.cycle_ignore_whitespace()
  M.state.ignore_whitespace = cycle_index(M.state.ignore_whitespace, IGNORE_CYCLE)
  return ignore_label()
end

function M.toggle_indent_heuristic()
  M.state.indent_heuristic = not M.state.indent_heuristic
  return M.state.indent_heuristic
end

function M.cycle_diff_algorithm()
  M.state.diff_algorithm = cycle_index(M.state.diff_algorithm, DIFF_ALGO_CYCLE)
  return DIFF_ALGO_CYCLE[M.state.diff_algorithm]
end

function M.cycle_conflict_style()
  M.state.conflict_style = cycle_index(M.state.conflict_style, CONFLICT_STYLE_CYCLE)
  return CONFLICT_STYLE_CYCLE[M.state.conflict_style]
end

function M.cycle_favor()
  M.state.favor = cycle_index(M.state.favor, FAVOR_CYCLE)
  return FAVOR_CYCLE[M.state.favor]
end

function M.cycle_merge_algorithm()
  M.state.merge_algorithm = cycle_index(M.state.merge_algorithm, MERGE_ALGO_CYCLE)
  return MERGE_ALGO_CYCLE[M.state.merge_algorithm]
end

---@return string[]
function M.status_lines()
  return {
    '── Diff display (live) ──',
    string.format('  ignore whitespace: %-10s [i] cycle', ignore_label()),
    string.format('  indent heuristic:  %-10s [h] toggle', M.state.indent_heuristic and 'on' or 'off'),
    string.format('  diff algorithm:    %-10s [a] cycle', DIFF_ALGO_CYCLE[M.state.diff_algorithm]),
  }
end

---@return string[]
function M.merge_status_lines()
  return {
    '── Merge recompute (git merge-file) ──',
    string.format('  conflict style:    %-10s [d] cycle', CONFLICT_STYLE_CYCLE[M.state.conflict_style]),
    string.format('  favor side:        %-10s [f] cycle', FAVOR_CYCLE[M.state.favor]),
    string.format('  merge algorithm:   %-10s [m] cycle', MERGE_ALGO_CYCLE[M.state.merge_algorithm]),
    '  whitespace ignore: display-only (git merge-file has no -Xignore-space)',
    '  [r] recompute into MERGED',
  }
end

---@return string[]
function M.all_status_lines()
  local lines = M.status_lines()
  for _, line in ipairs(M.merge_status_lines()) do
    table.insert(lines, line)
  end
  if M.state.last_error then
    table.insert(lines, '')
    table.insert(lines, 'Error: ' .. M.state.last_error)
  end
  return lines
end

---@return string
function M.merge_options_summary()
  return string.format(
    'style=%s favor=%s algo=%s',
    CONFLICT_STYLE_CYCLE[M.state.conflict_style],
    FAVOR_CYCLE[M.state.favor],
    MERGE_ALGO_CYCLE[M.state.merge_algorithm]
  )
end

---@param message string
---@return boolean
local function confirm(message)
  return vim.fn.confirm(message, '&Yes\n&No', 2) == 1
end

---@param force_confirm boolean
---@return boolean
function M.confirm_recompute(force_confirm)
  local merged_buf = detect.merged_bufnr()
  if not merged_buf then
    M.state.last_error = 'MERGED buffer not found'
    return false
  end

  if detect.has_conflict_markers(merged_buf) then
    if
      not confirm(
        'MERGED already contains conflict markers.\nRecompute will replace them with a fresh merge.\n\nDiscard existing markers and recompute?'
      )
    then
      return false
    end
  end

  if vim.bo[merged_buf].modified then
    local msg = 'Recompute will overwrite your resolution progress.\n\nOptions: '
      .. M.merge_options_summary()
      .. '\n\nContinue?'
    if not confirm(msg) then
      return false
    end
  elseif force_confirm then
    if not confirm('Recompute merge into MERGED?\n\nOptions: ' .. M.merge_options_summary()) then
      return false
    end
  end

  return true
end

---@param force_confirm boolean
---@return boolean success
function M.recompute(force_confirm)
  M.state.last_error = nil

  if vim.fn.executable('git') ~= 1 then
    M.state.last_error = 'git executable not found in PATH'
    return false
  end

  local local_path = vim.env.LOCAL
  local base_path = vim.env.BASE
  local remote_path = vim.env.REMOTE
  local merged_path = vim.env.MERGED

  if
    not local_path
    or local_path == ''
    or not remote_path
    or remote_path == ''
    or not merged_path
    or merged_path == ''
  then
    M.state.last_error = 'Missing LOCAL, REMOTE, or MERGED environment paths'
    return false
  end

  if not M.confirm_recompute(force_confirm) then
    return false
  end

  local cmd = {
    'git',
    'merge-file',
    '-p',
    '-L',
    'LOCAL',
    '-L',
    'BASE',
    '-L',
    'REMOTE',
  }

  local style = CONFLICT_STYLE_CYCLE[M.state.conflict_style]
  if style == 'diff3' then
    table.insert(cmd, '--diff3')
  elseif style == 'zdiff3' then
    table.insert(cmd, '--zdiff3')
  end

  local favor = FAVOR_CYCLE[M.state.favor]
  if favor == 'ours' then
    table.insert(cmd, '--ours')
  elseif favor == 'theirs' then
    table.insert(cmd, '--theirs')
  elseif favor == 'union' then
    table.insert(cmd, '--union')
  end

  table.insert(cmd, '--diff-algorithm=' .. MERGE_ALGO_CYCLE[M.state.merge_algorithm])

  if base_path and base_path ~= '' then
    table.insert(cmd, local_path)
    table.insert(cmd, base_path)
    table.insert(cmd, remote_path)
  else
    table.insert(cmd, local_path)
    table.insert(cmd, '/dev/null')
    table.insert(cmd, remote_path)
  end

  -- SECURITY-REVIEW: paths come from git mergetool env vars, not user input
  local result = vim.system(cmd, { text = true }):wait()

  if result.code == nil then
    M.state.last_error = 'git merge-file failed to run'
    return false
  end

  if not result.stdout or result.stdout == '' then
    M.state.last_error = 'git merge-file produced no output'
    if result.stderr and result.stderr ~= '' then
      M.state.last_error = M.state.last_error .. ': ' .. result.stderr
    end
    return false
  end

  local ok, err = pcall(function()
    local f = io.open(merged_path, 'w')
    if not f then
      error('cannot open MERGED for writing')
    end
    f:write(result.stdout)
    f:close()
  end)

  if not ok then
    M.state.last_error = 'Failed to write MERGED: ' .. tostring(err)
    return false
  end

  local merged_buf = detect.merged_bufnr()
  if merged_buf then
    vim.api.nvim_buf_call(merged_buf, function()
      vim.cmd('checktime')
      if vim.bo.modified then
        vim.cmd('edit!')
      end
    end)
  end

  vim.cmd('diffupdate')
  return true
end

return M
