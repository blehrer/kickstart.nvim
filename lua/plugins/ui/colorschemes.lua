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

vim.keymap.set({ 'n' }, '<leader>ut', function()
  ---@diagnostic disable-next-line: undefined-field
  local current = vim.opt.background._value
  if current == 'dark' then
    vim.opt.background = 'light'
  elseif current == 'light' then
    vim.opt.background = 'dark'
  else
    ---@diagnostic disable-next-line: undefined-field, param-type-mismatch
    vim.notify(string.format('vim.opt.backround is currently set to "%s"', current._value), 'warn')
  end
end, { desc = 'UI: Toggle light/dark' })

require 'lazy.types'
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
