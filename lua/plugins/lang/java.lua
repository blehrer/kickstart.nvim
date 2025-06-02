---@param toolname string
---@param version string | number
---@param default 'default'?
local function mise_where(toolname, version, default)
  local tool = toolname .. '@' .. version
  return {
    name = toolname,
    path = vim.system({ 'mise', 'where', tool }, { text = true }):wait().stdout:gsub('%s', ''),
    default = default and true or false,
  }
end

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
            require('lspconfig.configs.jdtls').default_config,
          },
        },
        setup = {
          jdtls = function()
            require('java').setup(require 'java.config')
            require('java').setup {
              -- Your custom nvim-java configuration goes here
            }
          end,
          require('lspconfig').jdtls.setup {
            settings = {
              java = {
                configuration = {
                  runtimes = {
                    mise_where('java', 21, 'default'),
                    mise_where('java', 23),
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
