require 'lazy.types'
require 'noice.config.cmdline'
---@type LazyPluginSpec
return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  opts = {
    cmdline = {
      ---@type table<string, CmdlineFormat>
      format = {
        -- cmdline = { pattern = '^:', icon = '❱', lang = 'vim' },
        -- search_down = { kind = 'search', pattern = '^/', icon = '  ', lang = 'regex' },
        -- search_up = { kind = 'search', pattern = '^%?', icon = '  ', lang = 'regex' },
      },
    },
  },
  keys = {
    {
      '<leader>sm',
      function()
        require('noice.commands').cmd 'telescope'
      end,
      mode = 'n',
      desc = '[S]earch [M]essages',
    },
  },
  dependencies = {
    'muniftanjim/nui.nvim',
  },
}
