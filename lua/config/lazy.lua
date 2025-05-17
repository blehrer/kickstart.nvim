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

local specs = {}
-- collect all subdirs of `plugins` as importable specs
for _, subdir in ipairs(plugin_subdirs) do
  table.insert(specs, { import = relativize(subdir) })
end

-- Setup lazy.nvim
require('lazy').setup {
  -- highlight-start
  spec = specs,
  -- spec = {
  --   { import = 'plugins' },
  -- },
  -- highlight-end
  -- Configure any other settings here. See the documentation for more details.

  -- automatically check for plugin updates
  checker = { enabled = true },
}
