local fts = {
  'markdown',
  'text',
  'tex',
  'plaintex',
  'norg',
}

---@param spec LazyKeysSpec
---@return LazyKeysSpec
local function ft_scoped(spec)
  return vim.tbl_extend('force', spec, { ft = fts })
end

---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'gaoDean/autolist.nvim',
  opts = {},
  ft = fts,
  keys = {
    ft_scoped { '<CR>', '<CR><cmd>AutolistNewBullet<cr>', mode = { 'i' } },
    ft_scoped { '<s-tab>', '<cmd>AutolistShiftTab<cr>', mode = { 'i' } },
    ft_scoped { '<tab>', '<cmd>AutolistTab<cr>', mode = { 'i' } },
    ft_scoped { '<<', '<<<cmd>AutolistRecalculate<cr>', mode = { 'n' } },
    ft_scoped { '<C-r>', '<cmd>AutolistRecalculate<cr>', mode = { 'n' } },
    ft_scoped { '<CR>', '<cmd>AutolistToggleCheckbox<cr><CR>', mode = { 'n' } },
    ft_scoped {
      '<leader>cn',
      function()
        require('autolist').cycle_next_dr()
      end,
      { expr = true },
      mode = { 'n' },
    },
    ft_scoped {
      '<leader>cp',
      function()
        require('autolist').cycle_prev_dr()
      end,
      { expr = true },
      mode = { 'n' },
    },
    ft_scoped { '>>', '>><cmd>AutolistRecalculate<cr>', mode = { 'n' } },
    ft_scoped { 'O', 'O<cmd>AutolistNewBulletBefore<cr>', mode = { 'n' } },
    ft_scoped { 'dd', 'dd<cmd>AutolistRecalculate<cr>', mode = { 'n' } },
    ft_scoped { 'o', 'o<cmd>AutolistNewBullet<cr>', mode = { 'n' } },
    ft_scoped { 'd', 'd<cmd>AutolistRecalculate<cr>', mode = { 'v' } },
  },
}
