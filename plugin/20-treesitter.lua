if vim.g.vscode then return end

vim.pack.add({ 'https://github.com/nvim-treesitter/nvim-treesitter' })

require('nvim-treesitter').setup({
  install_dir = vim.fn.stdpath('data') .. '/site',
})

local langs = {
  'bash',
  'comment',
  'css',
  'diff',
  'dockerfile',
  'git_config',
  'git_rebase',
  'gitattributes',
  'gitignore',
  'go',
  'goctl',
  'gomod',
  'gotmpl',
  'gowork',
  'graphql',
  'html',
  'hyprlang',
  'java',
  'javadoc',
  'javascript',
  'json',
  'kotlin',
  'lua',
  'make',
  'markdown',
  'markdown_inline',
  'mermaid',
  'python',
  'query',
  'ruby',
  'rust',
  'sql',
  'terraform',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

if vim.fn.has('nvim-0.12') == 1 then
  vim.schedule(function()
    require('nvim-treesitter').install(langs)
  end)
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('nvim-new-treesitter-highlight', { clear = true }),
  callback = function()
    if pcall(vim.treesitter.start) then
      vim.bo.syntax = 'OFF'
    end
  end,
})
