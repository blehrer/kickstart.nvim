local ensure_installed = {
  bashls = {},
  denols = {},
  jsonls = {},
  lua_ls = {},
  stylua = {},
  superhtml = {},
  taplo = {}, --toml
  ts_ls = {},
  vimls = {},
  yamlls = {},
}

local non_mason_lsp_configs = {
  ['wordnet-ls'] = {},
  ['cfn_ls'] = {},
}
---@module 'lazy.types'
---@type LazyPluginSpec[]
return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    enabled = true,
    ---@module 'lazydev'
    ---@type lazydev.Config
    opts = {
      integrations = {
        blink = true,
      },
      library = {
        -- Load luvit types when the `vim.uv` word is found
        -- See https://github.com/LuaLS/lua-language-server/wiki/Libraries#manually-applying
        -- for an explanation of `${3rd}`
        {
          path = '${3rd}/luv/library',
          words = { 'vim%.uv' },
        },
        -- {
        --   'LazyVim',
        --   words = 'LazyVim',
        -- },
        -- {
        --   'nvim-dapui',
        --   words = 'dapui',
        -- },
        -- {
        --   'vim',
        --   words = 'vim'
        -- },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      {
        'mason-org/mason.nvim',
        ---@module 'mason.settings'
        ---@type MasonSettings
        opts = {
          ui = {
            icons = {
              package_installed = '✓',
              package_pending = '➜',
              package_uninstalled = '✗',
            },
          },
        },
      },
      {
        'mason-org/mason-lspconfig.nvim',
        ---@module 'mason-lspconfig.settings'
        ---@type MasonLspconfigSettings
        opts = {
          automatic_enable = true,
          ensure_installed = vim.tbl_keys(ensure_installed),
        },
      },
      {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        ---@module 'mason-tool-installer'
        opts = {
          ensure_installed = vim.tbl_keys(ensure_installed),
        },
      },

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Inlay hints
      -- { 'lvimuser/lsp-inlayhints.nvim' },

      'b0o/SchemaStore.nvim',

      -- Allows extra capabilities provided by blink.cmp
      'saghen/blink.cmp',
    },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities({}, true)
      require('mason-lspconfig').setup {
        ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = ensure_installed[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            vim.lsp.enable(server_name)
            vim.lsp.config(server_name, server)
            -- require('lspconfig')[server_name].setup(server)
          end,
        },
      }

      -- Lsps not vended through Mason
      for k, v in pairs(non_mason_lsp_configs) do
        vim.lsp.enable(k)
        vim.lsp.config(k, v)
      end
    end,
    keys = {
      -- WARN: This is not Goto Definition, this is Goto Declaration.
      --  For example, in C this would take you to the header.
      { 'gD', vim.lsp.buf.declaration, desc = '[G]oto [D]eclaration' },

      -- Jump to the definition of the word under your cursor.
      --  This is where a variable was first declared, or where a function is defined, etc.
      --  To jump back, press <C-t>.
      { 'gd', vim.lsp.buf.definition, desc = '[G]oto [D]efinition' },

      -- Find references for the word under your cursor.
      { 'gr', vim.lsp.buf.references, desc = '[G]oto [R]eferences' },

      -- Jump to the implementation of the word under your cursor.
      --  Useful when your language has ways of declaring types without an actual implementation.
      { 'gI', vim.lsp.buf.implementation, desc = '[G]oto [I]mplementation' },

      -- Jump to the type of the word under your cursor.
      --  Useful when you're not sure what type a variable is and you want to see
      --  the definition of its *type*, not where it was *defined*.
      { '<leader>d', vim.lsp.buf.type_definition, desc = 'Type [D]efinition' },

      -- Fuzzy find all the symbols in your current workspace.
      --  Similar to document symbols, except searches over your entire project.
      { '<leader>ws', vim.lsp.buf.workspace_symbol, desc = '[W]orkspace [S]ymbols' },

      -- Rename the variable under your cursor.
      --  Most Language Servers support renaming across files, etc.
      { '<leader>rn', vim.lsp.buf.rename, desc = '[R]e[n]ame' },

      -- Execute a code action, usually your cursor needs to be on top of an error
      -- or a suggestion from your LSP for this to activate.
      { '<leader>ca', vim.lsp.buf.code_action, desc = '[C]ode [A]ction', { 'n', 'x' } },
      { '<C-Enter>', vim.lsp.buf.code_action, desc = '[C]ode [A]ction', { 'n', 'x' } },
    },
  },
  {
    'icholy/lsplinks.nvim',
    opts = {},
    keys = {
      {
        'gx',
        function()
          require('lsplinks').gx()
        end,
        desc = 'open via lsp, or fallback to default `open` behavior',
        mode = { 'n', 'v' },
      },
    },
  },
}
