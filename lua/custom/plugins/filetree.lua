-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
    {
      'stevearc/oil.nvim',
      ---@module 'oil'
      opts = {
        default_file_explorer = false,
        view_options = {
          show_hidden = true,
        },
      },
      -- Optional dependencies
      dependencies = { 'nvim-tree/nvim-web-devicons' }, -- use if prefer nvim-web-devicons
    },
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['e'] = {
            function(state)
              local node = state.tree:get_node()
              require('oil').open_float(node.name)
            end,
            desc = 'Edit with Oil.nvim',
          },
        },
      },
    },
  },
}
