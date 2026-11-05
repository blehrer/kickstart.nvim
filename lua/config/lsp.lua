local M = {}

local hammerspoon_annotations = vim.fn.expand('~/.hammerspoon/Spoons/EmmyLua.spoon/annotations')

-- Per-server overrides live in lsp/<server>.lua (loaded natively by vim.lsp.config).
M.ensure_installed = {
  'ts_ls',
  'eslint',
  'jdtls',
  'kotlin_lsp',
  'superhtml',
  'ruff',
  'basedpyright',
  'bashls',
  'lua_ls',
  'dockerls',
  'markdown_oxide',
  'jsonls',
  'yamlls',
  'gitlab_ci_ls',
  'taplo',
}

function M.setup_lazydev()
  local library = {
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
  }

  if vim.uv.fs_stat(hammerspoon_annotations) then
    table.insert(library, {
      path = hammerspoon_annotations,
      words = { 'hs%.', 'spoon' },
    })
  end

  require('lazydev').setup({
    library = library,
    integrations = {
      lspconfig = true,
      cmp = false,
    },
  })
end

local highlight_group = vim.api.nvim_create_augroup('nvim-new-lsp-highlight', { clear = false })

function M.setup_attach()
  vim.api.nvim_create_autocmd('LspDetach', {
    group = vim.api.nvim_create_augroup('nvim-new-lsp-detach', { clear = true }),
    callback = function(event)
      vim.lsp.buf.clear_references()
      vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = event.buf })
    end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('nvim-new-lsp-attach', { clear = true }),
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if not client then
        return
      end

      local bufnr = event.buf

      if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
        vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
      end

      vim.keymap.set('i', '<C-Space>', vim.lsp.completion.get, {
        buffer = bufnr,
        desc = 'LSP completion',
      })

      if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = bufnr,
          group = highlight_group,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = bufnr,
          group = highlight_group,
          callback = vim.lsp.buf.clear_references,
        })
      end
    end,
  })
end

function M.setup_keymaps()
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc, buffer = false })
  end

  map('n', 'gd', vim.lsp.buf.definition, 'LSP definition')
  map('n', 'gD', vim.lsp.buf.declaration, 'LSP declaration')
  map('n', 'gr', vim.lsp.buf.references, 'LSP references')
  map('n', 'gI', vim.lsp.buf.implementation, 'LSP implementation')
  map('n', '<leader>ld', vim.lsp.buf.type_definition, 'LSP type definition')
  map('n', '<leader>ws', vim.lsp.buf.workspace_symbol, 'LSP workspace symbols')
  map('n', '<leader>rn', vim.lsp.buf.rename, 'LSP rename')
  map({ 'n', 'x' }, '<leader>ca', require('config.code_actions').code_action, 'Code action')
end

function M.setup()
  vim.lsp.config('*', {
    capabilities = {
      textDocument = {
        semanticTokens = {
          multilineTokenSupport = true,
        },
      },
    },
    root_markers = {
      '.git',
      '.luarc.json',
      'package.json',
      'pyproject.toml',
      'build.gradle',
      'build.gradle.kts',
      'settings.gradle',
      'settings.gradle.kts',
    },
  })

  M.setup_lazydev()
  M.setup_attach()

  require('mason-lspconfig').setup({
    ensure_installed = M.ensure_installed,
    automatic_install = true,
    automatic_enable = { exclude = { 'kotlin_language_server', 'stylua', 'gradle_ls' } },
  })

  M.setup_keymaps()
  require('config.lsp_panels').setup_keymaps()

  vim.api.nvim_create_user_command('LspPanels', function()
    require('config.lsp_panels').toggle()
  end, { desc = 'Toggle LSP doc + symbol panels' })

  vim.api.nvim_create_user_command('LspInfo', function()
    vim.cmd('checkhealth vim.lsp')
  end, { desc = 'LSP health / attached clients' })

  vim.api.nvim_create_user_command('LspSwitch', function()
    require('config.lsp_switcher').open()
  end, { desc = 'Toggle / solo LSP servers for the current buffer' })

  vim.api.nvim_create_user_command('KlsRestart', function()
    for _, name in ipairs({ 'kotlin_lsp', 'kotlin_language_server' }) do
      for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
        vim.lsp.stop_client(client.id, true)
      end
    end
    local root = vim.fs.root(vim.fn.getcwd(), { 'build.gradle.kts', 'build.gradle', 'settings.gradle.kts' })
    if root then
      for _, name in ipairs({ 'kls_database.db', 'kls_database.db-journal' }) do
        local path = root .. '/' .. name
        if vim.uv.fs_stat(path) then
          os.remove(path)
        end
      end
    end
    vim.lsp.enable('kotlin_lsp')
    vim.notify('Kotlin language server restarted', vim.log.levels.INFO)
  end, { desc = 'Restart Kotlin LSP (JetBrains) and clear fwcd classpath cache if present' })
end

return M
