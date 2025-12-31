---@type {}LazyPluginSpec
return {
  {
    'linux-cultist/venv-selector.nvim',
    opts = {},
  },
  {
    'benomahony/uv.nvim',
    ---@type UVConfig
    opts = {
      auto_activate_venv = true,
      notify_activate_venv = true,
      keymaps = {
        prefix = '<leader>uv',
      },
    },
  },
}
