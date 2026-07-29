vim.pack.add({ 'https://github.com/folke/snacks.nvim' })

local exclude_patterns = { '*.class' }

require('snacks').setup({
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
    },
    preset = {
      keys = {
        {
          icon = ' ',
          key = 'f',
          desc = 'Find File',
          action = (":lua Snacks.dashboard.pick('files', {exclude = %s })"):format(vim.inspect(exclude_patterns)),
        },
        { icon = ' ', key = 'g', desc = 'Grep', action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
        {
          icon = ' ',
          key = 'c',
          desc = 'Config',
          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
        },
        { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
      },
      header = [[

                  _)             
  __ \   \ \   /   |   __ `__ \  
  |   |   \ \ /    |   |   |   | 
 _|  _|    \_/    _|  _|  _|  _| 
                                 
                                 

        ]],
    },
  },
  explorer = { enabled = false },
  gitbrowse = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  picker = {
    enabled = true,
    ui_select = true,
    layout = { preset = 'telescope', cycle = true },
    enter = true,
    win = {
      input = {
        keys = {
          ['<Esc><Esc>'] = { 'close', mode = { 'n', 'i' }, desc = 'Close' },
        },
      },
      list = {
        keys = {
          ['<Esc><Esc>'] = { 'close', mode = { 'n', 'i' }, desc = 'Close' },
        },
      },
    },
    sources = {
      colorschemes = {
        confirm = function(picker, item)
          picker:close()
          if item then
            picker.preview.state.colorscheme = nil
            vim.schedule(function()
              vim.fn.writefile({ item.text }, vim.fn.stdpath('data') .. '/colorscheme.current')
              vim.cmd('colorscheme ' .. item.text)
            end)
          end
        end,
      },
    },
  },
  notifier = {
    enabled = true,
    style = 'minimal',
    timeout = 7000,
    -- Errors stay until dismissed; everything else lands in history too.
    keep = function(notif)
      if vim.fn.getcmdpos() > 0 then
        return true
      end
      return notif.level == 'error'
    end,
  },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = false },
  statuscolumn = { enabled = true },
  words = { enabled = false },
  zen = { enabled = true },
})

vim.schedule(function()
  Snacks.input.enable()
end)

vim.keymap.set('n', '|', function()
  if vim.bo.filetype ~= 'snacks_dashboard' then
    Snacks.dashboard()
  end
end, { desc = 'Snacks dashboard' })

vim.keymap.set('n', '<leader><del>', function()
  Snacks.terminal.toggle()
end, { desc = 'Toggle terminal' })

vim.keymap.set('n', '<leader>sh', function()
  Snacks.picker.help()
end, { desc = 'Search help' })

vim.keymap.set('n', '<leader>sk', function()
  Snacks.picker.keymaps()
end, { desc = 'Search keymaps' })

vim.keymap.set('n', '<leader>sf', function()
  Snacks.picker.files({ exclude = exclude_patterns, hidden = true })
end, { desc = 'Search files' })

vim.keymap.set('n', '<leader>ss', function()
  Snacks.picker.pickers()
end, { desc = 'Search pickers' })

vim.keymap.set('n', '<leader>sg', function()
  Snacks.picker.grep({ hidden = true })
end, { desc = 'Search grep' })

vim.keymap.set('n', '<leader>sd', function()
  Snacks.picker.diagnostics()
end, { desc = 'Search diagnostics' })

vim.keymap.set('n', '<leader>sr', function()
  Snacks.picker.resume()
end, { desc = 'Search resume' })

vim.keymap.set('n', '<leader><leader>', function()
  Snacks.picker.buffers()
end, { desc = 'Search buffers' })

vim.keymap.set('n', '<Esc>', function()
  vim.cmd.nohlsearch()
end, { desc = 'Clear search highlight' })

local notifications = require('config.notifications')

-- Neovim requires an uppercase name; abbrev makes :notifications work at the prompt.
vim.api.nvim_create_user_command('Notifications', notifications.show, {
  desc = 'Notification history (like :messages)',
})
vim.cmd('cnoreabbrev notifications Notifications')

vim.keymap.set('n', '<leader>un', notifications.show, { desc = 'Notification history' })

vim.keymap.set('n', '<leader>uN', function()
  Snacks.notifier.hide()
end, { desc = 'Dismiss notifications' })

Snacks.toggle.option('spell', { name = 'Spelling' }):map('<leader>us')
Snacks.toggle.option('wrap', { name = 'Wrap' }):map('<leader>uw')
Snacks.toggle.diagnostics():map('<leader>ud')
Snacks.toggle.treesitter():map('<leader>uT')
Snacks.toggle.inlay_hints():map('<leader>uh')
Snacks.toggle.dim():map('<leader>uD')

vim.keymap.set('n', '<leader>uc', function()
  Snacks.picker.colorschemes()
end, { desc = 'Colorscheme picker' })
