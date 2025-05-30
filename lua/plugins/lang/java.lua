---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'nvim-java/nvim-java',
  lazy = true,
  dependencies = {
    {
      'neovim/nvim-lspconfig',
      opts = {
        servers = {
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
          require('lspconfig').jdtls.setup {
            settings = {
              java = {
                configuration = {
                  runtimes = {
                    {
                      name = 'mise@21',
                      path = vim.system({ 'mise', 'where', 'java@21' }, { text = true }):wait().stdout:gsub('%s', ''),
                      default = true,
                    },
                    {
                      name = 'mise@24',
                      path = vim.system({ 'mise', 'where', 'java@24' }, { text = true }):wait().stdout:gsub('%s', ''),
                      default = false,
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
}
