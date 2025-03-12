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
      dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = false },
      picker = { enabled = true, icons = {} },
      notifier = { enabled = false },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = false },
      statuscolumn = { enabled = true },
      words = { enabled = false },
    },
  },
  vim.keymap.set('n', '\\', function()
    require('snacks').explorer()
  end, { desc = 'Toggle the file explorer' }),
  vim.keymap.set('n', '|', function()
    require('snacks').dashboard()
  end, { desc = 'Snacks dashboard' }),
}
