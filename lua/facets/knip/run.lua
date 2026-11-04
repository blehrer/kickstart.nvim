local Item = require('trouble.item')

local M = {}

local NOTIFY_ID = 'facet-knip-run'
local inflight ---@type table|nil

local ISSUE_KEYS = {
  'binaries',
  'catalog',
  'catalogReferences',
  'cycles',
  'dependencies',
  'devDependencies',
  'duplicates',
  'enumMembers',
  'exports',
  'files',
  'namespaceMembers',
  'nsExports',
  'nsTypes',
  'optionalPeerDependencies',
  'types',
  'unlisted',
  'unresolved',
}

local function normalize_path(root, file)
  if not file or file == '' then
    return root
  end
  if file:match('^/') then
    return vim.fn.fnamemodify(file, ':p')
  end
  return vim.fn.fnamemodify(root .. '/' .. file, ':p')
end

local function message_for(kind, item)
  if type(item) ~= 'table' then
    return ('[%s] %s'):format(kind, tostring(item))
  end
  if item.name then
    return ('[%s] %s'):format(kind, item.name)
  end
  if item.specifier then
    return ('[%s] %s'):format(kind, item.specifier)
  end
  return ('[%s] %s'):format(kind, vim.inspect(item))
end

local function pos_from_item(item)
  local line = tonumber(item and item.line) or 1
  local col = math.max((tonumber(item and item.col) or 1) - 1, 0)
  return line, col
end

local function add_item(items, root, file, kind, item)
  local line, col = pos_from_item(item)
  items[#items + 1] = Item.new({
    source = 'facets_knip',
    filename = normalize_path(root, file),
    pos = { line, col },
    end_pos = { line, col },
    message = message_for(kind, item),
    code = kind,
    severity = vim.diagnostic.severity.WARN,
    item = item,
  })
end

local function add_nested(items, root, file, kind, nested)
  if type(nested) ~= 'table' then
    return
  end
  if nested[1] and type(nested[1]) == 'table' and nested[1].name == nil and nested[1].specifier == nil then
    for _, group in ipairs(nested) do
      if type(group) == 'table' then
        for _, sub in ipairs(group) do
          add_item(items, root, file, kind, sub)
        end
      end
    end
    return
  end
  for _, entry in ipairs(nested) do
    add_item(items, root, file, kind, entry)
  end
end

---@param report table
---@param root string
---@return trouble.Item[]
function M.parse_json(report, root)
  local items = {}
  if type(report) ~= 'table' or type(report.issues) ~= 'table' then
    return items
  end
  for _, row in ipairs(report.issues) do
    if type(row) == 'table' and row.file then
      for _, kind in ipairs(ISSUE_KEYS) do
        add_nested(items, root, row.file, kind, row[kind])
      end
    end
  end
  Item.add_id(items, { 'code', 'severity' })
  return items
end

---@param root string
---@param out_file string
---@return string[]
function M.knip_cmd(root, out_file)
  local bin = root .. '/node_modules/.bin/knip'
  local knip = vim.fn.executable(bin) == 1 and vim.fn.shellescape(bin) or 'npx knip'
  local out = vim.fn.shellescape(out_file)
  return { 'sh', '-c', knip .. ' --reporter json > ' .. out .. ' 2>&1' }
end

---@param ctx table
---@param cb fun(err?: string, items?: trouble.Item[])
function M.project_run(ctx, cb)
  if inflight then
    vim.notify('Knip already running', vim.log.levels.INFO, { id = NOTIFY_ID })
    return
  end

  local out_file = vim.fn.tempname() .. '.json'
  local cmd = M.knip_cmd(ctx.root, out_file)
  vim.notify(('Running %s …'):format(cmd[3] or 'knip'), vim.log.levels.INFO, {
    id = NOTIFY_ID,
    title = 'Knip',
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
        cb('Knip was interrupted')
        return
      end

      if vim.fn.filereadable(out_file) ~= 1 then
        cb('Knip produced no output')
        return
      end

      local text = table.concat(vim.fn.readfile(out_file), '\n')
      os.remove(out_file)

      local json_start = text:find('{')
      if not json_start then
        cb(vim.trim(text:sub(1, 500)))
        return
      end

      local ok, decoded = pcall(vim.fn.json_decode, text:sub(json_start))
      if not ok or type(decoded) ~= 'table' then
        cb('Could not parse Knip JSON output')
        return
      end

      local items = M.parse_json(decoded, ctx.root)
      if #items == 0 and result.code ~= 0 then
        cb(vim.trim(text:sub(1, 500)))
        return
      end

      cb(nil, items)
    end)
  end)
end

return M
