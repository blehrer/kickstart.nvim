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
  { 'rebelot/kanagawa.nvim', lazy = false, priority = 100 },
  very_lazy { 'metalelf0/base16-black-metal-scheme' },
  very_lazy { 'metalelf0/black-metal-theme-neovim' },
  very_lazy { 'metalelf0/base16-black-metal-scheme' },
  very_lazy { 'sho-87/kanagawa-paper.nvim' },
  very_lazy { 'folke/tokyonight.nvim' },
  very_lazy { 'rose-pine/neovim' },
  very_lazy { 'comfysage/evergarden' },
  very_lazy { 'nyoom-engineering/oxocarbon.nvim' },
  very_lazy { 'catppuccin/nvim', name = 'catppuccin' },
  very_lazy { 'foxoman/vim-helix' },
  very_lazy { 'vague2k/vague.nvim' },
  very_lazy { 'olivercederborg/poimandres.nvim' },
  very_lazy { 'slugbyte/lackluster.nvim' },
  very_lazy { 'aliqyan-21/darkvoid.nvim' },
  very_lazy { 'kdheepak/monochrome.nvim' },
  very_lazy { 'kyazdani42/blue-moon' },
  very_lazy { 'webhooked/kanso.nvim' },
  very_lazy { 'mellow-theme/mellow.nvim' },
  very_lazy { 'dgox16/oldworld.nvim' },
}
