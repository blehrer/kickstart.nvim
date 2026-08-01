if vim.g.vscode then return end

vim.pack.add({ 'https://github.com/folke/sidekick.nvim' })

require('sidekick').setup({
  cli = {
    mux = { backend = 'zellij', enabled = true },
  },
})

vim.keymap.set('n', '<Tab>', function()
  if not require('sidekick').nes_jump_or_apply() then
    return '<Tab>'
  end
end, { expr = true, desc = 'Goto/Apply Next Edit Suggestion' })

vim.keymap.set({ 'n', 't', 'i', 'x' }, '<C-.>', function()
  require('sidekick.cli').focus()
end, { desc = 'Sidekick Focus' })

vim.keymap.set('n', '<leader>aa', function()
  require('sidekick.cli').toggle()
end, { desc = 'Sidekick Toggle CLI' })

vim.keymap.set('n', '<leader>as', function()
  require('sidekick.cli').select()
end, { desc = 'Select CLI' })

vim.keymap.set('n', '<leader>ad', function()
  require('sidekick.cli').close()
end, { desc = 'Detach a CLI Session' })

vim.keymap.set({ 'n', 'x' }, '<leader>at', function()
  require('sidekick.cli').send({ msg = '{this}' })
end, { desc = 'Send This' })

local function send_file()
  local cli = require('sidekick.cli')

  if vim.bo.filetype == 'oil' then
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
      local path = vim.fs.normalize(vim.fs.join(dir, name))
      local display = path
      local ok, rel = pcall(vim.fs.relpath, cwd, path)
      if ok and rel and rel ~= '' and rel ~= '.' then
        display = rel
      end
      lines[#lines + 1] = '@' .. display
    end

    cli.send({ msg = table.concat(lines, '\n') })
    return
  end

  cli.send({ msg = '{file}' })
end

vim.keymap.set({ 'n', 'x' }, '<leader>af', send_file, { desc = 'Send File' })

vim.keymap.set('x', '<leader>av', function()
  require('sidekick.cli').send({ msg = '{selection}' })
end, { desc = 'Send Visual Selection' })

vim.keymap.set({ 'n', 'x' }, '<leader>ap', function()
  require('sidekick.cli').prompt()
end, { desc = 'Sidekick Select Prompt' })

vim.keymap.set('n', '<leader>ac', function()
  require('sidekick.cli').toggle({ name = 'claude', focus = true })
end, { desc = 'Sidekick Toggle Claude' })
