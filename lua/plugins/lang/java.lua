---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'nvim-java/nvim-java',
  dependencies = {
    {
      'neovim/nvim-lspconfig',
      opts = {
        servers = {
          ---@module 'lspconfig.configs.jdtls'
          jdtls = {
            -- Your custom jdtls settings goes here
          },
        },
        setup = {
          jdtls = function()
            require('java').setup {
              -- Your custom nvim-java configuration goes here
            }
          end,
        },
      },
    },
  },
}
