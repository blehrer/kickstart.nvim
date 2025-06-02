local log_level = vim.g.plugin_log_level
local log = require('logger'):new { log_level = log_level, prefix = ('%s'):format(debug.getinfo(1, 'S').short_src), echo_messages = false }
---@param tool string
---@param version string | number
---@param default 'default'?
local function mise_where(tool, version, default)
  local name = tool .. '@' .. version
  local success, result = pcall(function()
    return vim.system({ 'mise', 'where', name }, { text = true }):wait()
  end)
  if not success or result.code ~= 0 then
    log:error('`mise where' .. name .. '` failed')
    local term, code = os.execute 'command -v mise'
    if term == 'signal' then
      log:error('`command -v mise` was interrupted by signal', result.signal)
    elseif code ~= 0 then
      log:error '`mise` is not a known command'
    end
  else
    log:debug('result:', result)
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
