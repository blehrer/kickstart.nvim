---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'mawkler/refjump.nvim',
  opts = {
    integrations = {
      demicolon = {
        enable = true,
      },
    },
  },
  dependencies = {
    {
      {
        'nvim-treesitter/nvim-treesitter-textobjects',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
          require('nvim-treesitter.configs').setup {
            ensure_installed = 'all',
            textobjects = {
              move = {
                enable = true,
                goto_next_start = {
                  [']f'] = '@function.outer',
                  [']a'] = '@argument.outer',
                  [']m'] = '@method.outer',
                  -- ...
                },
                goto_previous_start = {
                  ['[f'] = '@function.outer',
                  ['[a'] = '@argument.outer',
                  ['[m'] = '@method.outer',
                  -- ...
                },
              },
            },
          }
        end,
      },
      {
        'jinh0/eyeliner.nvim',
        keys = { 't', 'f', 'T', 'F' },
        config = function()
          require('eyeliner').setup {
            highlight_on_key = true,
            dim = true,
            default_keymaps = false,
          }

          local function eyeliner_jump(key)
            local forward = vim.list_contains({ 't', 'f' }, key)
            return function()
              require('eyeliner').highlight { forward = forward }
              return require('demicolon.jump').horizontal_jump(key)()
            end
          end

          local map, nxo, opts = vim.keymap.set, { 'n', 'x', 'o' }, { expr = true }

          map(nxo, 'f', eyeliner_jump 'f', opts)
          map(nxo, 'F', eyeliner_jump 'F', opts)
          map(nxo, 't', eyeliner_jump 't', opts)
          map(nxo, 'T', eyeliner_jump 'T', opts)
        end,
      },
      {
        'mawkler/demicolon.nvim',
        dependencies = {
          'nvim-treesitter/nvim-treesitter',
          'nvim-treesitter/nvim-treesitter-textobjects',
        },
        opts = {
          keymaps = {
            horizontal_motions = false,
            -- `f` is removed from this table because we have mapped it to
            -- `@function.outer` with nvim-treesitter-textobjects
            disabled_keys = { 'p', 'I', 'A', 'i' },
          },
        },
      },
      opts = {},
    },
  },
  event = 'LspAttach',
}
