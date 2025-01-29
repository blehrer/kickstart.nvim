return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@diagnostic disable-next-line: undefined-doc-name
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    opts = {
      filesystem = {
        windows = {
          mapping = {
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
  },
}
