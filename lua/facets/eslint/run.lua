local Item = require('trouble.item')

local M = {}

local NOTIFY_ID = 'facet-eslint-run'
local inflight ---@type table|nil

local function eslint_severity(n)
  if n == 2 then
    return vim.diagnostic.severity.ERROR
  end
  if n == 1 then
    return vim.diagnostic.severity.WARN
  end
  return vim.diagnostic.severity.INFO
end

---@param results table[]
---@return trouble.Item[]
function M.parse_json_results(results)
  local items = {}
  for _, file in ipairs(results) do
    local path = file.filePath
    if type(path) == 'string' and type(file.messages) == 'table' then
      for _, msg in ipairs(file.messages) do
        local line = msg.line or 1
        local col = (msg.column or 1) - 1
        local end_line = msg.endLine or line
        local end_col = (msg.endColumn or msg.column or 1) - 1
        items[#items + 1] = Item.new({
          source = 'facets_eslint',
          filename = path,
          pos = { line, math.max(col, 0) },
          end_pos = { end_line, math.max(end_col, 0) },
          message = msg.message or '',
          code = msg.ruleId or '',
          severity = eslint_severity(msg.severity or 2),
          item = msg,
        })
      end
    end
  end
  Item.add_id(items, { 'code', 'severity' })
  return items
end

---@param root string
---@param out_file string
---@return string[]
function M.eslint_cmd(root, out_file)
  local args = { '.', '-f', 'json', '--max-warnings', '99999', '-o', out_file }
  local bin = root .. '/node_modules/.bin/eslint'
  if vim.fn.executable(bin) == 1 then
    return vim.list_extend({ bin }, args)
  end
  return vim.list_extend({ 'npx', 'eslint' }, args)
end

--- Run eslint on the whole project at git root.
---@param ctx table facets anchor ctx
---@param cb fun(err?: string, items?: trouble.Item[])
function M.project_lint(ctx, cb)
  if inflight then
    vim.notify('ESLint project lint already running', vim.log.levels.INFO, { id = NOTIFY_ID })
    return
  end

  -- ponytail: write JSON to disk; vim.system stdout truncates large eslint reports.
  local out_file = vim.fn.tempname() .. '.json'
  local cmd = M.eslint_cmd(ctx.root, out_file)
  vim.notify(('Running %s …'):format(table.concat(cmd, ' ')), vim.log.levels.INFO, {
    id = NOTIFY_ID,
    title = 'ESLint',
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
        cb('ESLint was interrupted')
        return
      end

      if vim.fn.filereadable(out_file) ~= 1 then
        local err = result.stderr and vim.trim(result.stderr:sub(1, 500)) or 'eslint produced no output file'
        cb(err)
        return
      end

      local json = table.concat(vim.fn.readfile(out_file), '\n')
      os.remove(out_file)

      local ok, decoded = pcall(vim.fn.json_decode, json)
      if not ok or type(decoded) ~= 'table' then
        cb('Could not parse eslint JSON output')
        return
      end

      cb(nil, M.parse_json_results(decoded))
    end)
  end)
end

return M
