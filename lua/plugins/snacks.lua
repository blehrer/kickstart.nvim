local exclude_patterns = { '*.class' }
---@module 'lazy.types'
---@type LazyPluginSpec[]
return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    dependencies = {
      { 'andre-kotake/nvim-chezmoi', opts = {} },
    },
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            {
              icon = ' ',
              key = 'f',
              desc = 'Find File',
              action = (":lua Snacks.dashboard.pick('files', {exclude = %s })"):format(vim.inspect(exclude_patterns)),
            },
            { icon = ' ', key = 'g', desc = 'Grep', action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = ' ', key = 'N', desc = 'New Note', action = ':Obsidian new' },
            { icon = '󰈞 ', key = 'n', desc = 'Find Notes', action = ':Obsidian quick_switch' },
            { icon = '󰈞 ', key = '/', desc = 'Grep Notes', action = ':Obsidian search' },
            { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
            { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
            { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
            {
              icon = ' ',
              key = 'z',
              desc = 'Chezmoi Dotfiles',
              action = ':ChezmoiManaged',
            },
          },
          header = [[

                  _)             
  __ \   \ \   /   |   __ `__ \  
  |   |   \ \ /    |   |   |   | 
 _|  _|    \_/    _|  _|  _|  _| 
                                 
                                 

        ]],
        },
      },
      gitbrowse = { enabled = true },
      explorer = { enabled = false },
      indent = { enabled = true },
      input = { enabled = false },
      picker = {
        enabled = true,
        ui_select = true,
        layout = {
          preset = 'telescope',
          cycle = true,
        },
        enter = true,
        win = {
          input = {
            keys = {
              ['PgDn'] = { 'list_scroll_down' },
              ['PgUp'] = { 'list_scroll_up' },
              ['<Esc><Esc>'] = { 'close', mode = { 'n', 'i' }, desc = 'Close' },
            },
          },
          list = {
            keys = {
              ['PgDn'] = { 'list_scroll_down' },
              ['PgUp'] = { 'list_scroll_up' },
              ['<Esc><Esc>'] = { 'close', mode = { 'n', 'i' }, desc = 'Close' },
            },
          },
          preview = {
            keys = {
              ['<Esc><Esc>'] = { 'close', mode = { 'n', 'i' }, desc = 'Close' },
            },
          },
          lazygit = {
            keys = {
              ['<Esc><Esc>'] = { 'close', mode = { 'n', 'i' }, desc = 'Close' },
            },
          },
        },
        sources = {
          colorschemes = {
            sort = function(a, b)
              return a.text:lower() > b.text:lower()
            end,
            confirm = function(picker, item)
              picker:close()
              if item then
                picker.preview.state.colorscheme = nil
                vim.schedule(function()
                  vim.fn.writefile({ item.text }, vim.fn.stdpath 'data' .. '/colorscheme.current')
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
        timeout = 2000,
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scratch = {
        enabled = true,
        win = {
          relative = 'editor',
          keys = {
            ['<Esc><Esc>'] = { 'close', mode = { 'n', 'i' }, desc = 'Close' },
          },
        },
      },
      scroll = { enabled = false },
      statuscolumn = { enabled = true },
      words = { enabled = false },
      zen = { enabled = true },
    },
    keys = {
      {
        '<Esc>',
        function()
          require('snacks.notifier').hide()
        end,
      },
      {
        '|',
        function()
          if vim.bo.filetype ~= 'snacks_dashboard' then
            require('snacks').dashboard()
          end
        end,
        desc = 'Snacks dashboard',
      },
      {
        '<leader><del>',
        function()
          require('snacks.terminal').toggle(nil, { cwd = vim.fn.expand '%:h', interactive = true })
        end,
        desc = 'Toggle terminal',
      },
      {
        '<leader>sp',
        function()
          require('snacks').picker()
        end,
        desc = '[S]nacks [P]icker',
      },
      {
        '<leader>uc',
        function()
          require('snacks.picker').colorschemes()
        end,
        desc = 'UI: Colorscheme picker',
      },
      {
        '<leader>sh',
        function()
          require('snacks.picker').help()
        end,
        desc = '[S]earch: [H]elp',
      },
      {
        '<leader>sk',
        function()
          require('snacks.picker').keymaps()
        end,
        desc = '[S]earch: [K]eymaps',
      },
      {
        '<leader>sf',
        function()
          require('snacks.picker').files { exclude = exclude_patterns }
        end,
        desc = '[S]earch: [F]iles',
      },
      {
        '<leader>ss',
        function()
          require('snacks.picker').pickers()
        end,
        desc = '[S]earch: [S]elect picker',
      },
      {
        '<leader>sg',
        function()
          require('snacks.picker').grep()
        end,
        desc = '[S]earch: [G]rep',
      },
      {
        '<leader>sd',
        function()
          require('snacks.picker').diagnostics()
        end,
        desc = '[S]earch: [D]iagnostics',
      },
      {
        '<leader>sr',
        function()
          require('snacks.picker').resume()
        end,
        desc = '[S]earch: [R]esume',
      },
      {
        'leader<sm>',
        function()
          require('snacks.picker').notifications()
        end,
      },
      {
        '<leader><leader>',
        function()
          require('snacks.picker').buffers()
        end,
        desc = '[S]earch: buffers',
      },
    },
    init = function()
      local snacks = require 'snacks'
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            snacks.debug.inspect(...)
          end
          _G.bt = function()
            snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Create some toggle mappings
          snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
          snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
          -- Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
          snacks.toggle.diagnostics():map '<leader>ud'
          -- Snacks.toggle.line_number():map("<leader>ul")
          snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>uc'
          snacks.toggle.treesitter():map '<leader>uT'
          snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>ub'
          snacks.toggle.inlay_hints():map '<leader>uh'
          -- Snacks.toggle.indent():map("<leader>ug")
          snacks.toggle.dim():map '<leader>uD'
        end,
      })
    end,
  },
}
