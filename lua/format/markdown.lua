local M = {}

local REF_DEF = '^%s*%[[^%]]+%]:'
local REF_INLINE = '%[[^%]]+%]%[[^%]]+%]'
local LINK_INLINE = '%[[^%]]+%]%([^%)]+%)'
local FMT_IGNORE = '<!-- md-fmt-ignore -->'

local function is_table_line(line)
  return line:match('^%s*|') ~= nil
end

local function is_fence_line(line)
  return line:match('^%s*```') ~= nil or line:match('^%s*~~~') ~= nil
end

function M.should_skip(lines)
  for _, line in ipairs(lines) do
    if is_table_line(line) or is_fence_line(line) then
      return true
    end
  end
  return false
end

local function line_needs_guard(line)
  return line:match(REF_INLINE) ~= nil or line:match(LINK_INLINE) ~= nil
end

local function collapse_prettier_ref_damage(lines)
  local out = {}
  local i = 1
  while i <= #lines do
    local line = lines[i]
    if i < #lines and line:match('^(%s*%[[^%]]+%]:)%s*$') then
      local next_line = lines[i + 1]
      if next_line:match('^%s+https?://') or next_line:match('^%s+//') then
        table.insert(out, line .. ' ' .. vim.trim(next_line))
        i = i + 2
        goto continue
      end
    end
    if i < #lines and line:match('%[[^%]]*$') and not line:match('%]%[') then
      local next_line = lines[i + 1]
      if next_line:match('%]%[[^%]]+%]') then
        table.insert(out, line .. ' ' .. vim.trim(next_line))
        i = i + 2
        goto continue
      end
    end
    table.insert(out, line)
    i = i + 1
    ::continue::
  end
  return out
end

local function split_trailing_ref_defs(lines)
  local refs = {}
  local i = #lines
  while i >= 1 do
    local line = lines[i]
    if line:match(REF_DEF) then
      table.insert(refs, 1, line)
      i = i - 1
    elseif line:match('^%s*$') and #refs > 0 then
      i = i - 1
    else
      break
    end
  end
  local body = {}
  for j = 1, i do
    body[j] = lines[j]
  end
  return body, refs
end

local function inject_fmt_ignore(lines)
  local out = {}
  for _, line in ipairs(lines) do
    if line_needs_guard(line) then
      table.insert(out, FMT_IGNORE)
    end
    table.insert(out, line)
  end
  return out
end

local function strip_fmt_ignore(lines)
  local out = {}
  local i = 1
  while i <= #lines do
    local line = lines[i]
    if line:match('^%s*<!%-%- md%-fmt%-ignore %-%->%s*$') then
      i = i + 1
      if i <= #lines and lines[i]:match('^%s*$') then
        i = i + 1
      end
    else
      table.insert(out, line)
      i = i + 1
    end
  end
  return out
end

local function resolve_filename(filename)
  if filename and filename ~= '' then
    return filename
  end
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= '' then
    return bufname
  end
  return 'buffer.md'
end

local function prettier_cmd(filename)
  local mason = vim.fs.find({ 'node_modules/.bin/prettier', 'node_modules/.bin/prettier.cmd' }, {
    upward = true,
    path = resolve_filename(filename),
  })[1]
  if mason then
    return mason
  end
  return 'prettier'
end

function M.prettier_format_lines(lines, filename)
  filename = resolve_filename(filename)
  lines = collapse_prettier_ref_damage(lines)
  local body, refs = split_trailing_ref_defs(lines)
  local stdin_lines = inject_fmt_ignore(body)

  local cwd = vim.fn.fnamemodify(filename, ':p:h')
  if cwd == '' or cwd == filename then
    cwd = vim.loop.cwd()
  end

  local result = vim.system({
    prettier_cmd(filename),
    '--parser',
    'markdown',
    '--prose-wrap',
    'always',
    '--stdin-filepath',
    filename,
  }, {
    cwd = cwd,
    stdin = table.concat(stdin_lines, '\n'),
    text = true,
  }):wait()

  if result.code ~= 0 then
    return false, lines
  end

  local stdout = result.stdout or ''
  if vim.trim(stdout) == '' and #stdin_lines == 0 then
    return true, refs
  end

  local out = vim.split(vim.trim(stdout, { trimempty = false }), '\n', { plain = true })
  if #out == 1 and out[1] == '' and #stdin_lines == 1 and stdin_lines[1] == '' then
    out = { '' }
  end
  out = strip_fmt_ignore(out)

  if #refs > 0 then
    if #out > 0 and out[#out] ~= '' then
      table.insert(out, '')
    end
    vim.list_extend(out, refs)
  end
  return true, out
end

function M.formatexpr()
  local lnum = vim.v.lnum
  local count = vim.v.count
  if lnum <= 0 or count <= 0 then
    return 1
  end

  local end_lnum = lnum + count - 1
  local lines = vim.api.nvim_buf_get_lines(0, lnum - 1, end_lnum, false)
  if #lines == 0 or M.should_skip(lines) then
    return 0
  end

  local ok, out = M.prettier_format_lines(lines)
  if not ok then
    return 1
  end

  vim.api.nvim_buf_set_lines(0, lnum - 1, end_lnum, false, out)
  return 0
end

---@type conform.FileLuaFormatterConfig
M.conform = {
  meta = {
    description = 'Prettier for markdown (ref-safe preprocessing)',
  },
  format = function(_, ctx, lines, callback)
    local ok, out = M.prettier_format_lines(lines, ctx.filename)
    if not ok then
      callback('markdown prettier failed')
      return
    end
    callback(nil, out)
  end,
}

return M
