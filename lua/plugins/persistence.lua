require('lazy.types')
---@type LazyPluginSpec[]
return {
  {
    'folke/persistence.nvim',
    dependencies = {
      'folke/edgy.nvim',
      'oskarrrrrrr/symbols.nvim',
      'roobert/hoversplit.nvim',
    },
    opts = function()
      local edgy = require('edgy')
      local hoversplit = require('hoversplit')
      edgy.setup({
        ---@type Edgy.View.Opts[]
        right = {
          {
            title = 'Lsp Symbols',
            ft = 'snacks_picker_list',
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == ''
            end,
            pinned = true
          }
        }
      })
    end
  }
}
