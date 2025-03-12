require 'lazy'
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
  dependencies = {
    'muniftanjim/nui.nvim',
  },
}
