function SavedColorscheme()
  local fallback = 'habamax'
  local cs_data_file = vim.fn.stdpath 'data' .. '/colorscheme.current'
  if vim.uv.fs_stat(cs_data_file) then
    local cs = vim.fn.readfile(cs_data_file, nil, 1)[1] or fallback
    vim.cmd.colorscheme(cs)
    return cs
  end
  vim.cmd.colorscheme(fallback)
  return fallback
end

---@param plugin LazyPluginSpec
---@return LazyPluginSpec
local function very_lazy(plugin)
  ---@type LazyPluginSpec
  local extension = {
    event = 'VeryLazy',
    dir = vim.fn.stdpath 'config' .. '/colors',
  }
  return vim.tbl_extend('force', plugin, { event = 'VeryLazy' })
end

---@module 'lazy.types'
---@type LazyPluginSpec[]
return {
  { 'sho-87/kanagawa-paper.nvim', lazy = false, priority = 100 },
  very_lazy { 'rebelot/kanagawa.nvim' },
  very_lazy { 'comfysage/evergarden' },
  very_lazy { 'vague2k/vague.nvim' },
  very_lazy { 'olivercederborg/poimandres.nvim' },
  very_lazy { 'slugbyte/lackluster.nvim' },
  very_lazy { 'aliqyan-21/darkvoid.nvim' },
  very_lazy { 'kyazdani42/blue-moon' },
  very_lazy { 'webhooked/kanso.nvim' },
}
