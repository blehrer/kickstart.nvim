local mason_lsps = {
  lemminx = {},
  bashls = {},
  -- denols = {},
  jsonls = {},
  jdtls = {},
  lua_ls = {},
  markdown_oxide = {},
  ts_query_ls = {}, --treesitter query
  superhtml = {},
  taplo = {}, --toml
  ts_ls = {},
  vimls = {},
  yamlls = {},
}

local non_mason_lsps = {
  ['wordnet-ls'] = {},
  ['cfn_ls'] = {},
}

local all_lsps = vim.tbl_deep_extend('force', mason_lsps, non_mason_lsps)

local other_mason_tools = {
  stylua = {},
  ['java-debug-adpater'] = {},
  ['java-test'] = {},
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
  { 'mfussenegger/nvim-jdtls' },
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
          ensure_installed = vim.tbl_keys(mason_lsps),
        },
      },
      {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        ---@module 'mason-tool-installer'
        opts = {
          ensure_installed = vim.tbl_keys(other_mason_tools),
          auto_update = true,
        },
        config = function(self, opts)
          require('mason-tool-installer').setup(opts)
          vim.api.nvim_create_autocmd('User', {
            pattern = 'MasonToolsStartingInstall',
            callback = function()
              vim.schedule(function()
                print 'mason-tool-installer is starting'
              end)
            end,
          })
          vim.api.nvim_create_autocmd('User', {
            pattern = 'MasonToolsUpdateCompleted',
            callback = function(e)
              vim.schedule(function()
                print(vim.inspect(e.data)) -- print the table that lists the programs that were installed
              end)
            end,
          })
        end,
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
      local include_nvim_defaults = true
      local blink_capabilities = require('blink.cmp').get_lsp_capabilities({}, include_nvim_defaults)
      for name, merge_target_config in pairs(all_lsps) do
        merge_target_config.capabilities = vim.tbl_deep_extend('force', blink_capabilities, merge_target_config.capabilities or {})
        vim.lsp.config(name, merge_target_config) -- see :help lsp-config
        vim.lsp.enable(name)
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
