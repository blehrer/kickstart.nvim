---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'gaoDean/autolist.nvim',
  opts = {},
  ft = {
    'markdown',
    'text',
    'tex',
    'plaintex',
    'norg',
  },
  keys = {
    { '<CR>', '<CR><cmd>AutolistNewBullet<cr>', mode = { 'i' } },
    { '<s-tab>', '<cmd>AutolistShiftTab<cr>', mode = { 'i' } },
    { '<tab>', '<cmd>AutolistTab<cr>', mode = { 'i' } },
    { '<<', '<<<cmd>AutolistRecalculate<cr>', mode = { 'n' } },
    { '<C-r>', '<cmd>AutolistRecalculate<cr>', mode = { 'n' } },
    { '<CR>', '<cmd>AutolistToggleCheckbox<cr><CR>', mode = { 'n' } },
    {
      '<leader>cn',
      function()
        require('autolist').cycle_next_dr()
      end,
      { expr = true },
      mode = { 'n' },
    },
    {
      '<leader>cp',
      function()
        require('autolist').cycle_prev_dr()
      end,
      { expr = true },
      mode = { 'n' },
    },
    { '>>', '>><cmd>AutolistRecalculate<cr>', mode = { 'n' } },
    { 'O', 'O<cmd>AutolistNewBulletBefore<cr>', mode = { 'n' } },
    { 'dd', 'dd<cmd>AutolistRecalculate<cr>', mode = { 'n' } },
    { 'o', 'o<cmd>AutolistNewBullet<cr>', mode = { 'n' } },
    { 'd', 'd<cmd>AutolistRecalculate<cr>', mode = { 'v' } },
  },
}
