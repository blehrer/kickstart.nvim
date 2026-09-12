local policy = require('format.policy')
local workspace = require('nx.workspace')

local M = {}

local LINT_SCRIPT_NAMES = { 'lint-fix', 'lint:fix' }

local resolve_cache = {}

local function nx_mtime(root)
  return vim.fn.getftime(root .. '/nx.json')
end

local function rel_path(root, filename)
  root = vim.fn.fnamemodify(root, ':p'):gsub('/$', '')
  filename = vim.fn.fnamemodify(filename, ':p')
  if filename:sub(1, #root + 1) ~= root .. '/' then
    return nil
  end
  return filename:sub(#root + 2)
end

local function package_manager(root)
  if vim.fn.filereadable(root .. '/bun.lockb') == 1 or vim.fn.filereadable(root .. '/bun.lock') == 1 then
    return 'bun'
  end
  if vim.fn.filereadable(root .. '/pnpm-lock.yaml') == 1 then
    return 'pnpm'
  end
  if vim.fn.filereadable(root .. '/yarn.lock') == 1 then
    return 'yarn'
  end
  return 'npm'
end

local function script_cmd(root, script, filename)
  local pm = package_manager(root)
  if pm == 'yarn' then
    return { pm, script, filename }
  end
  if pm == 'npm' then
    return { pm, 'run', script, '--', filename }
  end
  if pm == 'pnpm' then
    return { pm, script, filename }
  end
  return { pm, 'run', script, filename }
end

local function lint_script(scripts)
  for _, name in ipairs(LINT_SCRIPT_NAMES) do
    if scripts and scripts[name] then
      return name
    end
  end
  return nil
end

local function cache_key(root, rel)
  local remote_id = workspace.git_remote_id(root) or root
  return remote_id .. '\0' .. rel .. '\0' .. tostring(nx_mtime(root))
end

local function build_commands(root, rel, filename, match)
  local cmds = {}
  if match.format_write then
    cmds[#cmds + 1] = workspace.nx_cmd(root, { 'format:write', '--files=' .. rel })
  end
  if match.lint_fix then
    local script = lint_script(policy.load(root).scripts)
    if script then
      cmds[#cmds + 1] = script_cmd(root, script, filename)
    end
  end
  if #cmds == 0 then
    return nil
  end
  return cmds
end

--- Skip auto-format when project config says this file is out of scope.
function M.skip(bufnr)
  bufnr = bufnr or 0
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == '' then
    return false
  end

  local root = workspace.root(filename)
  if not root then
    return false
  end

  local rel = rel_path(root, filename)
  if not rel then
    return false
  end

  local p = policy.load(root)
  if p.lint_staged then
    return policy.match(root, rel) == nil
  end

  return policy.prettier_ignored(root, rel)
end

--- Resolve CI formatting strategy for a buffer, or nil when config has no rule.
function M.resolve(bufnr)
  bufnr = bufnr or 0
  if M.skip(bufnr) then
    return nil
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == '' or vim.bo[bufnr].buftype ~= '' then
    return nil
  end

  local root = workspace.root(filename)
  if not root then
    return nil
  end

  local rel = rel_path(root, filename)
  if not rel then
    return nil
  end

  local key = cache_key(root, rel)
  if resolve_cache[key] then
    return resolve_cache[key]
  end

  local match = policy.match(root, rel)
  if not match then
    return nil
  end

  local cmds = build_commands(root, rel, filename, match)
  if not cmds then
    return nil
  end

  local strategy = {
    kind = #cmds == 1 and 'single' or 'chain',
    root = root,
    filename = filename,
    cmds = cmds,
  }
  resolve_cache[key] = strategy
  return strategy
end

function M.available(bufnr)
  return M.resolve(bufnr) ~= nil
end

local function run_commands(strategy, callback)
  for _, cmd in ipairs(strategy.cmds) do
    local result = vim.system(cmd, { cwd = strategy.root, text = true }):wait()
    if result.code ~= 0 then
      local err = (result.stderr and vim.trim(result.stderr) ~= '') and vim.trim(result.stderr)
        or ('CI format failed (exit ' .. tostring(result.code) .. ')')
      callback(err)
      return
    end
  end
  callback(nil)
end

--- Conform formatter factory: runs lint-staged-equivalent commands in place.
function M.formatter(bufnr)
  return {
    format = function(_, ctx, input_lines, callback)
      local strategy = M.resolve(ctx.buf)
      if not strategy then
        callback(nil, input_lines)
        return
      end

      run_commands(strategy, function(err)
        if err then
          callback(err)
          return
        end
        callback(nil, vim.fn.readfile(strategy.filename))
      end)
    end,
  }
end

function M.invalidate()
  resolve_cache = {}
  policy.invalidate()
end

return M
