---@type LazyPluginSpec[]
return {
  {
    'tlj/api-browser.nvim',
    dependencies = {
      'kkharji/sqlite.lua',
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'mfussenegger/nvim-dap',
      'rcarriga/nvim-dap-ui',
    },
    config = function()
      require('api-browser').setup()
    end,
    keys = {
      { '<leader>aa', '<cmd>ApiBrowser open<cr>', desc = 'Select an API.' },
      { '<leader>ad', '<cmd>ApiBrowser select_local_server<cr>', desc = 'Select environment.' },
      { '<leader>ax', '<cmd>ApiBrowser select_remote_server<cr>', desc = 'Select remote environment.' },
      { '<leader>ae', '<cmd>ApiBrowser endpoints<cr>', desc = 'Open list of endpoints for current API.' },
      { '<leader>ar', '<cmd>ApiBrowser recents<cr>', desc = 'Open list of recently opened API endpoints.' },
      { '<leader>ag', '<cmd>ApiBrowser endpoints_with_param<cr>', desc = 'Open API endpoints valid for replacement text on cursor.' },
    },
  },
}
