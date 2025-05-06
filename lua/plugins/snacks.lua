require 'lazy.types'
---@type LazyPluginSpec[]
return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          header = [[

                  _)             
  __ \   \ \   /   |   __ `__ \  
  |   |   \ \ /    |   |   |   | 
 _|  _|    \_/    _|  _|  _|  _| 
                                 
                                 

        ]],
        },
      },
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
      notifier = { enabled = false },
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
        '<leader>.',
        function()
          Snacks.scratch()
        end,
        desc = 'Toggle Scratch Buffer',
      },
      {
        '<leader>S/',
        function()
          Snacks.scratch.open()
        end,
        desc = 'Toggle Scratch Buffer',
      },
      {
        '|',
        function()
          if vim.bo.filetype ~= 'snacks_dashboard' then
            Snacks.dashboard()
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
          Snacks.picker()
        end,
        desc = '[S]nacks [P]icker',
      },
      {
        '<leader>uc',
        function()
          Snacks.picker.colorschemes()
        end,
        desc = 'UI: Colorscheme picker',
      },
    },
  },
}
