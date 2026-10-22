local M = {}

local hammerspoon_annotations = vim.fn.expand('~/.hammerspoon/Spoons/EmmyLua.spoon/annotations')
local hammerspoon_dir = vim.fn.expand('~/.hammerspoon')

--- Per-server vim.lsp.config overrides (merged by mason-lspconfig / vim.lsp.enable).
M.servers = {
  ts_ls = {},
  -- vscode-eslint / mason eslint: flat config repos (eslint.config.js) need useFlatConfig.
  eslint = {
    settings = {
      experimental = { useFlatConfig = true },
      workingDirectory = { mode = 'auto' },
      validate = 'on',
      run = 'onType',
    },
  },
  jdtls = {},
  -- JetBrains kotlin-lsp (Gradle/Kotlin 2.3+). fwcd kotlin_language_server ships Kotlin 2.1 and
  -- breaks on Gradle 9.x stdlib 2.3 metadata; keep it out of ensure_installed / automatic_enable.
  kotlin_lsp = {
    filetypes = { 'kotlin' },
    cmd_env = vim.fn.environ(),
  },
  superhtml = {},
  gradle_ls = {},
  pylsp = {},
  bashls = {
    filetypes = { 'bash', 'sh', 'zsh' },
  },
  lua_ls = {
    settings = {
      Lua = {
        format = { enable = false },
      },
    },
    on_attach = function(client, bufnr)
      local path = vim.api.nvim_buf_get_name(bufnr)
      if path == '' or not path:find(hammerspoon_dir, 1, true) then
        return
      end

      local library = {}
      if vim.uv.fs_stat(hammerspoon_annotations) then
        table.insert(library, hammerspoon_annotations)
      end

      if #library == 0 then
        return
      end

      client.notify('workspace/didChangeConfiguration', {
        settings = {
          Lua = {
            diagnostics = { globals = { 'hs', 'spoon' } },
            workspace = { library = library },
          },
        },
      })
    end,
  },
  dockerls = {
    filetypes = { 'dockerfile' },
  },
  -- Only attach in PKM vaults; upstream includes `.git` and wedges non-vault repos on open.
  markdown_oxide = {
    root_markers = { '.obsidian', '.moxide.toml' },
    workspace_required = true,
  },
}

M.ensure_installed = vim.tbl_keys(M.servers)

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

  for name, cfg in pairs(M.servers) do
    vim.lsp.config(name, cfg)
  end

  M.setup_lazydev()

  require('mason-lspconfig').setup({
    ensure_installed = M.ensure_installed,
    automatic_install = true,
    automatic_enable = { exclude = { 'kotlin_language_server' } },
  })

  M.setup_keymaps()
  require('config.lsp_panels').setup_keymaps()

  vim.api.nvim_create_user_command('LspPanels', function()
    require('config.lsp_panels').toggle()
  end, { desc = 'Toggle LSP doc + symbol panels' })

  vim.api.nvim_create_user_command('LspInfo', function()
    vim.cmd('checkhealth vim.lsp')
  end, { desc = 'LSP health / attached clients' })

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
