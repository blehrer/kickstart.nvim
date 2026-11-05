local modules = {
  'mini.icons',
  'snacks',
  'which-key',
  'oil',
  'bqf',
  'trouble',
  'todo-comments',
  'mason',
  'conform',
  'guess-indent',
  'nvim-autopairs',
  'dial.config',
  'autolist',
  'refjump',
  'colorizer',
  'scissors',
  'refactoring',
  'render-markdown',
  'image',
  'dap',
  'dap-view',
  'persistent-breakpoints',
  'dap-breakpoints',
  'neotest',
  'neotest-playwright',
  'gitsigns',
  'neogit',
  'codereview',
  'sidekick',
  'nvim-treesitter',
  'rest-nvim',
  'fidget',
  'tiny-cmdline',
  'lazydev',
  'lspconfig',
}

local failed = {}
for _, mod in ipairs(modules) do
  local ok, err = pcall(require, mod)
  if not ok then
    table.insert(failed, mod .. ': ' .. tostring(err))
  end
end

if #failed > 0 then
  vim.api.nvim_echo({ { 'check-plugins FAILED\n', 'ErrorMsg' } }, true, {})
  for _, line in ipairs(failed) do
    vim.api.nvim_echo({ { line .. '\n', 'WarningMsg' } }, true, {})
  end
  error('check-plugins failed')
end

vim.api.nvim_echo({ { ('check-plugins OK (%d modules)\n'):format(#modules), 'MoreMsg' } }, true, {})
