local config = require('markdown_xanadu.config')

local M = {}

---@param file string
---@return string
local function basename(file)
  local base = vim.fn.fnamemodify(file, ':t'):gsub('%.md$', '')
  return base
end

---@param file string
---@param root string
---@return string[]
function M.find_sync(file, root)
  root = root or config.fixture_root()
  root = vim.fn.fnamemodify(root, ':p'):gsub('/$', '')
  local base = basename(file)
  local rel = file
  if rel:find(root, 1, true) == 1 then
    rel = rel:sub(#root + 2):gsub('%.md$', '')
  else
    rel = vim.fn.fnamemodify(file, ':t'):gsub('%.md$', '')
  end

  local patterns = {
    '[[' .. rel .. ']]',
    '[[' .. rel .. '#',
    '![[' .. rel .. ']]',
    '[[' .. base .. ']]',
    '[[' .. base .. '#',
    '![[' .. base .. ']]',
    rel .. '.md',
    base .. '.md',
  }

  local seen = {}
  local results = {}

  local cmd = { 'rg', '-l', '--glob', '*.md', '-F' }
  for _, p in ipairs(patterns) do
    cmd[#cmd + 1] = '-e'
    cmd[#cmd + 1] = p
  end
  cmd[#cmd + 1] = root

  local proc = vim.system(cmd, { text = true }):wait()
  if proc.code ~= 0 and proc.code ~= 1 then
    return results
  end

  local self_norm = vim.fn.fnamemodify(file, ':p')
  for line in (proc.stdout or ''):gmatch('[^\n]+') do
    local full = vim.fn.fnamemodify(line, ':p')
    if full:sub(1, #root) ~= root then
      full = root .. '/' .. line
      full = vim.fn.fnamemodify(full, ':p')
    end
    if not seen[full] and full ~= self_norm then
      seen[full] = true
      results[#results + 1] = full
    end
  end

  table.sort(results)
  return results
end

---@param file string
---@param opts? { root?: string, on_done: fun(files: string[]) }
function M.find(file, opts)
  opts = opts or {}
  local root = opts.root or config.fixture_root()
  vim.schedule(function()
    local files = M.find_sync(file, root)
    if opts.on_done then
      opts.on_done(files)
    end
  end)
end

---@param file string
---@param files string[]
function M.show_picker(file, files)
  if #files == 0 then
    vim.notify('No backlinks found', vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, f in ipairs(files) do
    items[#items + 1] = {
      text = vim.fn.fnamemodify(f, ':.'),
      file = f,
    }
  end
  if pcall(require, 'snacks') then
    Snacks.picker({
      title = ('Backlinks (%d)'):format(#items),
      items = items,
      confirm = function(picker, item)
        picker:close()
        if item and item.file then
          vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
        end
      end,
    })
  else
    vim.ui.select(vim.tbl_map(function(it)
      return it.text
    end, items), {}, function(choice)
      if not choice then
        return
      end
      for _, it in ipairs(items) do
        if it.text == choice then
          vim.cmd('edit ' .. vim.fn.fnameescape(it.file))
          break
        end
      end
    end)
  end
end

return M
