---@param tool string
---@param version string | number
---@param default 'default'?
local function mise_where(tool, version, default)
  local name = tool .. '@' .. version
  local success, result = pcall(function()
    return vim.system({ 'mise', 'where', tool }, { text = true }):wait()
  end)
  local path = success and result.stdout:gsub('%s', '') or nil
  local is_default = default and true or false
  if name and path then
    return {
      name = name,
      path = path,
      default = is_default,
    }
  end
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
                    mise_where('java', 24),
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
