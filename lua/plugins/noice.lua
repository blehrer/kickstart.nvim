---@module 'lazy.types'
---@module "noice.types"
---@type LazyPluginSpec[]
return {
  {
    'folke/noice.nvim',
    ---@type LazyPluginSpec[]
    dependencies = {
      {
        'muniftanjim/nui.nvim',
      },
    },
    event = 'VeryLazy',
    ---@type NoiceConfig
    opts = {
      view = {
        ---@type NoiceViewOptions
        opts = {
          win_options = {
            wrap = true,
          },
        },
      },
      lsp = {
        hover = {
          view = 'vsplit',
          ---@type NoiceViewOptions
          opts = {
            ---@diagnostic disable-next-line: missing-fields
            win_options = {
              number = false,
              relativenumber = false,
            },
          },
        },
        documentation = {
          view = 'vsplit',
        },
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
        },
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = false, -- use a classic bottom cmdline for search
        -- command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
        command_palette = {
          views = {
            cmdline_popup = {
              position = {
                row = '50%',
                col = '50%',
              },
              size = {
                min_width = 60,
                width = 'auto',
                height = 'auto',
              },
            },
            cmdline_popupmenu = {
              relative = 'editor',
              position = {
                row = 6,
                col = '50%',
              },
              size = {
                width = 60,
                height = 'auto',
                max_height = 15,
              },
              border = {
                style = 'rounded',
                padding = { 0, 1 },
              },
              win_options = {
                winhighlight = { Normal = 'Normal', FloatBorder = 'NoiceCmdlinePopupBorder' },
              },
            },
          },
        },
      },
    },
    keys = {
      {
        '<leader>sm',
        function()
          require('noice.commands').cmd 'telescope'
        end,
        mode = 'n',
        desc = '[S]earch [M]essages',
      },
    },
  },
}
