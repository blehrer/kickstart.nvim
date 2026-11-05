if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/NMAC427/guess-indent.nvim',
})

require('guess-indent').setup({})

local deference = require('format.deference')
local format_hunks = require('format.hunks')

local function format_opts(bufnr)
  bufnr = bufnr or 0
  if deference.skip(bufnr) then
    return nil
  end
  if deference.available(bufnr) then
    return {
      timeout_ms = 3000,
      formatters = { 'project_ci' },
      lsp_format = 'never',
      stop_after_first = true,
    }
  end
  local disable = { c = true, cpp = true }
  return {
    timeout_ms = 500,
    lsp_format = disable[vim.bo[bufnr].filetype] and 'never' or 'fallback',
  }
end

local function is_project_ci(opts)
  return opts.formatters and opts.formatters[1] == 'project_ci'
end

require('conform').setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    if not vim.g.format_on_save then
      return false
    end
    local opts = format_opts(bufnr)
    if not opts then
      return false
    end
    -- Nx project_ci always formats the whole file; no range API.
    if is_project_ci(opts) then
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
      require_cwd = true,
      condition = function(_, ctx)
        return not deference.skip(ctx.buf)
      end,
    },
  },
  formatters_by_ft = {
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
  local opts = format_opts(0)
  if not opts then
    return
  end
  require('conform').format(vim.tbl_extend('force', opts, { async = true }))
end

local function format_hunks_key()
  local opts = format_opts(0)
  if not opts then
    return
  end
  if is_project_ci(opts) then
    vim.notify('Hunk format is not available for Nx project_ci; use <leader>fF', vim.log.levels.INFO)
    return
  end
  if not format_hunks.format(0, opts) then
    vim.notify('No git hunks to format', vim.log.levels.INFO)
  end
end

vim.keymap.set('n', '<leader>ff', format_hunks_key, { desc = 'Format git hunks' })
vim.keymap.set('n', '<leader>fF', format_whole, { desc = 'Format whole buffer' })

-- gq → prettier on prose (tables/fences skipped); ref links guarded automatically.
-- Last resort: <!-- prettier-ignore-start --> … <!-- prettier-ignore-end --> in the file.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  group = vim.api.nvim_create_augroup('format-markdown', { clear = true }),
  callback = function()
    vim.bo.formatexpr = "v:lua.require'format.markdown'.formatexpr()"
    if not vim.bo.formatoptions:find('t', 1, true) then
      vim.bo.formatoptions = vim.bo.formatoptions .. 't'
    end
  end,
})
