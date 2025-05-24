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

---@module 'lazy.types'
---@type LazyPluginSpec[]
return {
  { 'folke/tokyonight.nvim' },
  { 'rose-pine/neovim' },
  { 'sho-87/kanagawa-paper.nvim' },
  { 'comfysage/evergarden' },
  { 'nyoom-engineering/oxocarbon.nvim' },
  { 'catppuccin/nvim', name = 'catppuccin' },
  { 'foxoman/vim-helix' },
  { 'vague2k/vague.nvim' },
  { 'olivercederborg/poimandres.nvim' },
  { 'slugbyte/lackluster.nvim' },
  { 'aliqyan-21/darkvoid.nvim' },
  { 'kdheepak/monochrome.nvim' },
  { 'kyazdani42/blue-moon' },
}
