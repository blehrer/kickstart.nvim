if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/NMAC427/guess-indent.nvim',
})

require('mason').setup()

require('guess-indent').setup({})

require('conform').setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    local disable = { c = true, cpp = true }
    return {
      timeout_ms = 500,
      lsp_format = disable[vim.bo[bufnr].filetype] and 'never' or 'fallback',
    }
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'black' },
    json = { 'fixjson' },
    markdown = { 'prettier' },
    typescript = { 'prettier' },
    javascript = { 'prettier' },
  },
})

vim.keymap.set('n', '<leader>f', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer' })
