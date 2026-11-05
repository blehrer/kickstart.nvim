if vim.g.vscode then return end

local buf = vim.api.nvim_get_current_buf()

vim.keymap.set('n', '~', function()
  vim.api.nvim_set_current_dir(require('oil').get_current_dir(0) or '.')
end, { buffer = buf, desc = 'Set cwd to Oil directory' })

vim.keymap.set('n', '<leader>y', function()
  local oil = require('oil')
  local dir = oil.get_current_dir()
  if not dir then
    return
  end

  local entry = oil.get_cursor_entry()
  if not entry or entry.name == '..' or entry.id == 0 then
    return
  end

  local path = vim.fs.normalize(vim.fs.joinpath(dir, entry.parsed_name or entry.name))
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local rel = path

  local ok, result = pcall(vim.fs.relpath, cwd, path)
  if ok and result and result ~= '' and result ~= '.' then
    rel = result
  end

  if not vim.startswith(rel, '/') and not vim.startswith(rel, './') then
    rel = './' .. rel
  end

  vim.fn.setreg('+', rel)
  vim.fn.setreg('"', rel)
end, { buffer = buf, desc = 'Copy path relative to cwd' })

vim.keymap.set({ 'n', 'x' }, '<leader>af', function()
  local oil = require('oil')
  local oil_util = require('oil.util')
  local dir = oil.get_current_dir()
  if not dir then
    return
  end

  local entries = {}
  local range = oil_util.get_visual_range()
  if range then
    for lnum = range.start_lnum, range.end_lnum do
      local entry = oil.get_entry_on_line(0, lnum)
      if entry and entry.name ~= '..' and entry.id ~= 0 then
        entries[#entries + 1] = entry
      end
    end
  else
    local entry = oil.get_cursor_entry()
    if entry and entry.name ~= '..' and entry.id ~= 0 then
      entries[#entries + 1] = entry
    end
  end

  if #entries == 0 then
    require('sidekick.util').warn('Nothing to send.')
    return
  end

  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local lines = {}
  for _, entry in ipairs(entries) do
    local name = entry.parsed_name or entry.name
    if entry.type == 'directory' and not vim.endswith(name, '/') then
      name = name .. '/'
    end
    local path = vim.fs.normalize(vim.fs.joinpath(dir, name))
    local display = path
    local ok, rel = pcall(vim.fs.relpath, cwd, path)
    if ok and rel and rel ~= '' and rel ~= '.' then
      display = rel
    end
    lines[#lines + 1] = '@' .. display
  end

  require('sidekick.cli').send({ msg = table.concat(lines, '\n') })
end, { buffer = buf, desc = 'Send Oil entry to Sidekick' })
