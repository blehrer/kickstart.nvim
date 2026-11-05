local Item = require('trouble.item')

local M = {}

M.id = 'typescript.tsc'
M.requires = { 'node' }

M.trouble = {
  label = 'TypeScript (tsc --noEmit)',
  runner = 'tsc',
}

function M.detect(ctx)
  return vim.fn.filereadable(ctx.root .. '/tsconfig.json') == 1
    or vim.fn.filereadable(ctx.root .. '/tsconfig.build.json') == 1
end

local NOTIFY_ID = 'facet-tsc-run'
local inflight ---@type table|nil

-- path(line,col): error TS2322: message
-- Lua patterns have no | alternation; match error/warning as a word.
local LINE_PAT = '^([^%(]+)%((%d+),(%d+)%):%s(%a+)%s+TS(%d+):%s(.+)%s*$'

local function severity(kind)
  if kind == 'warning' then
    return vim.diagnostic.severity.WARN
  end
  return vim.diagnostic.severity.ERROR
end

---@param text string
---@param root string
---@return trouble.Item[]
function M.parse_output(text, root)
  root = vim.fn.fnamemodify(root, ':p'):gsub('/$', '')
  local items = {}
  for line in (text .. '\n'):gmatch('([^\n]*)\n') do
    local path, lnum, col, kind, code_num, message = line:match(LINE_PAT)
    if path and lnum and (kind == 'error' or kind == 'warning') then
      local code = 'TS' .. code_num
      if not path:match('^/') then
        path = vim.fn.fnamemodify(root .. '/' .. path, ':p')
      end
      local line_n = tonumber(lnum) or 1
      local col_n = math.max((tonumber(col) or 1) - 1, 0)
      items[#items + 1] = Item.new({
        source = 'facets_tsc',
        filename = path,
        pos = { line_n, col_n },
        end_pos = { line_n, col_n },
        message = message or '',
        code = code or '',
        severity = severity(kind),
        item = { line = line },
      })
    end
  end
  Item.add_id(items, { 'code', 'severity' })
  return items
end

---@param root string
---@param out_file string
---@return string[]
function M.tsc_cmd(root, out_file)
  local bin = root .. '/node_modules/.bin/tsc'
  local tsc = vim.fn.executable(bin) == 1 and vim.fn.shellescape(bin) or 'npx tsc'
  local out = vim.fn.shellescape(out_file)
  return { 'sh', '-c', tsc .. ' --noEmit --pretty false > ' .. out .. ' 2>&1' }
end

---@param ctx table
---@param cb fun(err?: string, items?: trouble.Item[])
function M.project_check(ctx, cb)
  if inflight then
    vim.notify('tsc already running', vim.log.levels.INFO, { id = NOTIFY_ID })
    return
  end

  local out_file = vim.fn.tempname() .. '.log'
  local cmd = M.tsc_cmd(ctx.root, out_file)
  vim.notify(('Running %s …'):format(cmd[3] or 'tsc'), vim.log.levels.INFO, {
    id = NOTIFY_ID,
    title = 'tsc',
  })

  inflight = vim.system(cmd, {
    cwd = ctx.root,
    text = true,
    env = vim.fn.environ(),
  }, function(result)
    inflight = nil
    vim.schedule(function()
      if result.code == nil then
        os.remove(out_file)
        cb('tsc was interrupted')
        return
      end

      if vim.fn.filereadable(out_file) ~= 1 then
        cb('tsc produced no output')
        return
      end

      local text = table.concat(vim.fn.readfile(out_file), '\n')
      os.remove(out_file)

      local items = M.parse_output(text, ctx.root)
      -- tsc exits 1 when there are errors; still parsed
      if #items == 0 and result.code ~= 0 then
        local snippet = vim.trim(text:sub(1, 500))
        if snippet ~= '' then
          cb(snippet)
          return
        end
        cb('tsc failed with no parseable diagnostics')
        return
      end

      cb(nil, items)
    end)
  end)
end

return M
