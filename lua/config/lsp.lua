local M = {}

local hammerspoon_annotations = vim.fn.expand('~/.hammerspoon/Spoons/EmmyLua.spoon/annotations')
local hammerspoon_dir = vim.fn.expand('~/.hammerspoon')

--- Per-server vim.lsp.config overrides (merged by mason-lspconfig / vim.lsp.enable).
M.servers = {
  ts_ls = {},
  jdtls = {},
  kotlin_language_server = {},
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
  map({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, 'LSP code action')
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
    automatic_enable = true,
  })

  M.setup_keymaps()

  vim.api.nvim_create_user_command('LspInfo', function()
    vim.cmd('checkhealth vim.lsp')
  end, { desc = 'LSP health / attached clients' })
end

return M
