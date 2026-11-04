if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/mason-org/mason-lspconfig.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/folke/lazydev.nvim',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/NMAC427/guess-indent.nvim',
})

require('mason').setup()
require('config.lsp').setup()

require('guess-indent').setup({})

local deference = require('format.deference')
local format_hunks = require('format.hunks')

local prettier_config_cache = {}

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
    if not vim.g.format_on_save then
      return false
    end
    if deference.skip(bufnr) then
      return false
    end
    local opts = format_opts(bufnr)
    -- Nx project_ci always formats the whole file; no range API.
    if opts.formatters and opts.formatters[1] == 'project_ci' then
      return opts
    end
    if format_hunks.format(bufnr, opts) then
      return false
    end
    return opts
  end,
  default_format_opts = {
    stop_after_first = true,
    lsp_format = 'fallback',
  },
  formatters = {
    project_ci = function(bufnr)
      return deference.formatter(bufnr)
    end,
    markdown_prettier = require('format.markdown').conform,
    prettier = {
      condition = function(_, ctx)
        if deference.skip(ctx.buf) then
          return false
        end
        if vim.bo[ctx.buf].filetype == 'markdown' then
          return false
        end
        local path = prettier_config_cache[ctx.filename]
        if path == nil then
          vim.fn.system({ 'prettier', '--find-config-path', ctx.filename })
          path = vim.v.shell_error == 0
          prettier_config_cache[ctx.filename] = path
        end
        return path
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
    markdown = { 'markdown_prettier' },
    typescript = { 'prettier' },
    javascript = { 'prettier' },
    kotlin = function(bufnr)
      local reg = require('facets.registry')
      local ctx = reg.resolve(bufnr)
      if not ctx then
        return {}
      end
      for _, entry in ipairs(reg.active(ctx)) do
        if entry.def.id == 'kotlin.jvm' and entry.def.conform_formatters then
          return entry.def.conform_formatters(ctx) or {}
        end
      end
      return {}
    end,
  },
})

local function format_whole()
  if deference.skip(0) then
    return
  end
  require('conform').format(vim.tbl_extend('force', format_opts(0), { async = true }))
end

local function format_hunks_key()
  if deference.skip(0) then
    return
  end
  local bufnr = 0
  local opts = format_opts(bufnr)
  if opts.formatters and opts.formatters[1] == 'project_ci' then
    vim.notify('Hunk format is not available for Nx project_ci; use <leader>fF', vim.log.levels.INFO)
    return
  end
  if not format_hunks.format(bufnr, opts) then
    vim.notify('No git hunks to format', vim.log.levels.INFO)
  end
end

vim.keymap.set('n', '<leader>ff', format_hunks_key, { desc = 'Format git hunks' })
vim.keymap.set('n', '<leader>fF', format_whole, { desc = 'Format whole buffer' })
