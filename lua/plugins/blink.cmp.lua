return {
  {
    'saghen/blink.compat',
    lazy = true,
  },
  {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          'rafamadriz/friendly-snippets',
          config = function(_, opts)
            require('luasnip.loaders.from_vscode').lazy_load()
            local luasnip = require 'luasnip'
            if opts then
              luasnip.config.setup(opts)
            end
            vim.tbl_map(function(type)
              require('luasnip.loaders.from_' .. type).lazy_load()
            end, { 'vscode', 'snipmate', 'lua' })
            luasnip.filetype_extend('python', { 'django' })
            luasnip.filetype_extend('htmldjango', { 'djangohtml' })
          end,
        },
      },
      {
        'folke/lazydev.nvim',
      },
      {
        'rcarriga/cmp-dap',
        dependencies = {
          'mfussenegger/nvim-dap',
        },
      },
      {
        'obsidian-nvim/obsidian.nvim',
      },
    },
    event = 'VimEnter',

    -- use a release tag to download pre-built binaries
    version = '1.*',
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = {
        preset = 'default',
        ['<C-h>'] = { 'snippet_backward', 'fallback' },
        ['<C-l>'] = { 'snippet_forward', 'fallback' },
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      -- (Default) Only show the documentation popup when manually triggered
      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        documentation = {
          auto_show = false,
          auto_show_delay_ms = 500,
        },
      },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = function()
          local defaults = { 'lsp', 'snippets', 'path' }
          local ft = vim.bo.filetype
          local node = vim.treesitter.get_node()
          if node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
            return { 'buffer' }
          elseif vim.filetype._findany(ft, { 'toml', 'yaml', 'json', 'jsonc' }) then
            return vim.list_extend(defaults, {
              'buffer',
            })
          elseif ft:match 'dap' then
            return vim.list_extend(defaults, {
              'dap',
            })
          elseif ft:match 'lua' then
            return vim.list_extend(defaults, { 'lazydev' })
          else
            return defaults
          end
        end,
        providers = {
          lazydev = {
            module = 'lazydev.integrations.blink',
            score_offset = 100,
            enabled = function()
              local sesh = require('dap').session()
              return vim.bo.filetype:match 'lua' or (sesh and sesh.adapter.options.source_filetype:match 'lua')
            end,
          },
          dap = {
            name = 'dap',
            module = 'blink.compat.source',
            enabled = function()
              return require('cmp_dap').is_dap_buffer()
            end,
          },
        },
      },

      snippets = { preset = 'luasnip' },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = 'prefer_rust_with_warning' },
      signature = { enabled = true },
    },
    opts_extend = { 'sources.default', 'sources.completion.enabled_providers' },
  },
}
