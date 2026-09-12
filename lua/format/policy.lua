local workspace = require('nx.workspace')

local M = {}

local cache = {}
local match_cache = {}

local NODE_MATCHER = [[
const mm = require('micromatch');
const ls = JSON.parse(process.argv[1]);
const rel = process.argv[2];
const out = { format_write: false, lint_fix: false };
for (const [pat, cmds] of Object.entries(ls)) {
  if (!mm.isMatch(rel, pat)) continue;
  for (const c of cmds) {
    if (c.includes('format:write')) out.format_write = true;
    if (c.includes('lint-fix') || /eslint\s+--fix/.test(c)) out.lint_fix = true;
  }
}
process.stdout.write(JSON.stringify(out));
]]

--- ponytail: studio-monorepo lint-staged shapes only; falls back when micromatch/node missing.
local function glob_match_lua(pat, rel)
  local braces = pat:match('^{([^}]+)}/%*%*/')
  if braces then
    local matched_dir = false
    for dir in braces:gmatch('[^,]+') do
      if rel:match('^' .. vim.pesc(dir) .. '/') then
        matched_dir = true
        break
      end
    end
    if not matched_dir then
      return false
    end
    local exts = pat:match('%.%{%?([^}]+)%}$') or pat:match('%.%{([^}]+)%}$')
    if exts then
      for ext in exts:gmatch('[^,]+') do
        if rel:match('%.' .. vim.pesc(ext) .. '$') then
          return true
        end
      end
      return false
    end
    return true
  end

  local prefix = pat:match('^([^%*]+)%*%*')
  if prefix and prefix ~= '' then
    return rel:sub(1, #prefix) == prefix
  end

  return rel == pat
end

local function classify_lint_staged(lint_staged)
  local rules = {}
  for pat, cmds in pairs(lint_staged) do
    if type(cmds) == 'table' then
      local format_write, lint_fix = false, false
      for _, cmd in ipairs(cmds) do
        if type(cmd) == 'string' then
          if cmd:find('format:write', 1, true) then
            format_write = true
          end
          if cmd:find('lint-fix', 1, true) or (cmd:find('eslint', 1, true) and cmd:find('--fix', 1, true)) then
            lint_fix = true
          end
        end
      end
      if format_write or lint_fix then
        rules[#rules + 1] = { pattern = pat, format_write = format_write, lint_fix = lint_fix }
      end
    end
  end
  return rules
end

local function match_lint_staged_lua(rules, rel)
  local out = { format_write = false, lint_fix = false }
  for _, rule in ipairs(rules) do
    if glob_match_lua(rule.pattern, rel) then
      if rule.format_write then
        out.format_write = true
      end
      if rule.lint_fix then
        out.lint_fix = true
      end
    end
  end
  if not out.format_write and not out.lint_fix then
    return nil
  end
  return out
end

local function match_lint_staged_node(root, lint_staged, rel)
  local mm = root .. '/node_modules/micromatch'
  if vim.fn.isdirectory(mm) ~= 1 then
    return nil
  end
  local ok, result = pcall(function()
    return vim
      .system({
        'node',
        '-e',
        NODE_MATCHER,
        vim.fn.json_encode(lint_staged),
        rel,
      }, { cwd = root, text = true })
      :wait()
  end)
  if not ok or not result or result.code ~= 0 or not result.stdout or result.stdout == '' then
    return nil
  end
  local decoded_ok, data = pcall(vim.fn.json_decode, result.stdout)
  if not decoded_ok or type(data) ~= 'table' then
    return nil
  end
  if not data.format_write and not data.lint_fix then
    return nil
  end
  return data
end

local function read_prettierignore(root)
  local path = root .. '/.prettierignore'
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end
  local patterns = {}
  for _, line in ipairs(vim.fn.readfile(path)) do
    line = vim.trim(line)
    if line ~= '' and not line:match('^#') then
      patterns[#patterns + 1] = line
    end
  end
  return patterns
end

--- ponytail: naive prefix/glob — good enough for typical .prettierignore entries.
local function prettier_ignored(patterns, rel)
  for _, pat in ipairs(patterns) do
    if pat:sub(1, 1) == '/' then
      pat = pat:sub(2)
    end
    if pat:sub(-1) == '/' then
      if rel:find('/' .. pat, 1, true) == 1 or rel:find(pat, 1, true) == 1 then
        return true
      end
    elseif pat:find('%*') then
      local re = '^' .. pat:gsub('%.', '%%.'):gsub('%*%*', '.*'):gsub('%*', '[^/]*') .. '$'
      if rel:match(re) then
        return true
      end
    elseif rel == pat or rel:match('/' .. pat .. '$') or rel:sub(1, #pat) == pat then
      return true
    end
  end
  return false
end

local function prettierignore_mtime(root)
  local path = root .. '/.prettierignore'
  return vim.fn.filereadable(path) == 1 and vim.fn.getftime(path) or 0
end

function M.load(root)
  local pkg_path = root .. '/package.json'
  local pkg_mtime = vim.fn.filereadable(pkg_path) == 1 and vim.fn.getftime(pkg_path) or 0
  local pi_mtime = prettierignore_mtime(root)
  local key = root .. '\0' .. tostring(pkg_mtime) .. '\0' .. tostring(pi_mtime)

  if cache[key] then
    return cache[key]
  end

  local pkg = workspace.read_json(pkg_path)
  local lint_staged = pkg and pkg['lint-staged']
  local policy = {
    root = root,
    lint_staged = type(lint_staged) == 'table' and lint_staged or nil,
    lint_rules = type(lint_staged) == 'table' and classify_lint_staged(lint_staged) or {},
    scripts = pkg and pkg.scripts or {},
    prettierignore = read_prettierignore(root),
  }
  cache[key] = policy
  return policy
end

function M.match(root, rel)
  local policy = M.load(root)
  if not policy.lint_staged then
    return nil
  end

  local cache_key = policy.root .. '\0' .. rel
  if match_cache[cache_key] then
    return match_cache[cache_key]
  end

  local matched = match_lint_staged_node(root, policy.lint_staged, rel)
    or match_lint_staged_lua(policy.lint_rules, rel)
  match_cache[cache_key] = matched
  return matched
end

function M.prettier_ignored(root, rel)
  local policy = M.load(root)
  return prettier_ignored(policy.prettierignore, rel)
end

function M.invalidate()
  cache = {}
  match_cache = {}
end

return M
