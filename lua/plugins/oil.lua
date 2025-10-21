return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      preview_win = {
        update_on_cursor_moved = true,
        show_hidden = true,
      },
    },
    -- Optional dependencies
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    keys = {
      {
        '-',
        function()
          require('oil').open_float()
        end,
      },
    },
  },
}
