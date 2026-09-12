if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/NMAC427/guess-indent.nvim',
})

require('mason').setup()

require('guess-indent').setup({})

local deference = require('format.deference')

local function format_opts(bufnr)
  local disable = { c = true, cpp = true }
  local lsp_format = disable[vim.bo[bufnr].filetype] and 'never' or 'fallback'
  if deference.available(bufnr) then
    return {
      timeout_ms = 3000,
      formatters = { 'project_ci' },
      lsp_format = 'never',
      stop_after_first = true,
    }
  end
  return {
    timeout_ms = 500,
    lsp_format = lsp_format,
  }
end

require('conform').setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    if deference.skip(bufnr) then
      return false
    end
    return format_opts(bufnr)
  end,
  default_format_opts = {
    stop_after_first = true,
    lsp_format = 'fallback',
  },
  formatters = {
    project_ci = function(bufnr)
      return deference.formatter(bufnr)
    end,
    prettier = {
      condition = function(_, ctx)
        if deference.skip(ctx.buf) then
          return false
        end
        vim.fn.system({ 'prettier', '--find-config-path', ctx.filename })
        return vim.v.shell_error == 0
      end,
    },
  },
  formatters_by_ft = {
    ['*'] = function(bufnr)
      if deference.available(bufnr) then
        return { 'project_ci' }
      end
      return {}
    end,
    lua = { 'stylua' },
    python = { 'black' },
    json = { 'fixjson' },
    markdown = { 'prettier' },
    typescript = { 'prettier' },
    javascript = { 'prettier' },
  },
})

vim.keymap.set('n', '<leader>f', function()
  if deference.skip(0) then
    return
  end
  if deference.available(0) then
    require('conform').format({
      async = true,
      formatters = { 'project_ci' },
      lsp_format = 'never',
      stop_after_first = true,
    })
  else
    require('conform').format({ async = true, lsp_format = 'fallback' })
  end
end, { desc = 'Format buffer' })
