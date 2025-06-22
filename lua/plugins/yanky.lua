---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'gbprod/yanky.nvim',
  opts = {
    textobj = {
      enabled = true,
    },
  },
  keys = {
    {
      '<leader>p',
      function()
        ---@diagnostic disable-next-line: undefined-field
        Snacks.picker.yanky()
      end,
      mode = { 'n', 'x' },
      desc = 'Open Yank History',
    },
    {
      'gp',
      function()
        require('yanky.textobj').last_put()
      end,
      { mode = { 'o', 'x' } },
    },
  },
}
