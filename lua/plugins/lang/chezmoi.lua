---@module 'config.functions'
---@module 'lazy.types'
---@type LazyPluginSpec[]
return {
  {
    -- highlighting for chezmoi files template files
    'alker0/chezmoi.vim',
    cond = HasChezmoi,
    init = function()
      vim.g['chezmoi#use_tmp_buffer'] = 1
      vim.g['chezmoi#source_dir_path'] = os.getenv 'HOME' .. '/.local/share/chezmoi'
    end,
  },
  {
    'andre-kotake/nvim-chezmoi',
    cond = HasChezmoi,
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-telescope/telescope.nvim' },
    },
    opts = {},
    keys = {
      {
        '<leader>sz',
        function()
          vim.cmd 'ChezmoiManaged'
        end,
        desc = '[S]earch: Dotfiles (che[z]moi)',
      },
    },
  },
}
