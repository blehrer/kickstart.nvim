vim.g.lazyvim_check_order = false
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

local plugin_subdirs = vim.tbl_filter(function(e)
  return vim.fn.isdirectory(e) == 1
end, vim.split(vim.fn.globpath(vim.fn.stdpath 'config' .. '/lua', 'plugins**'), '\n'))

local relativize = function(path)
  local relative_path = vim.fs.relpath(vim.fn.stdpath 'config' .. '/lua', path)
  return string.gsub(relative_path or '', '/', '.')
end

local specs = { { 'LazyVim/LazyVim' } }
-- collect all subdirs of `plugins` as importable specs
for _, subdir in ipairs(plugin_subdirs) do
  table.insert(specs, { import = relativize(subdir) })
end

-- Setup lazy.nvim
require('lazy').setup {
  spec = specs,
  checker = { enabled = true },
  rocks = {
    enabled = false,
  },
}

require('lazy').setup {
  spec = specs,
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        'tohtml',
        'tutor',
      },
    },
  },
}
