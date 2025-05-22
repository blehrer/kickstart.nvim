return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    local hotkey = '<C-s>'
    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup {

      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        add = hotkey .. 'a', -- Add surrounding in Normal and Visual modes
        delete = hotkey .. 'd', -- Delete surrounding
        find = hotkey .. 'f', -- Find surrounding (to the right)
        find_left = hotkey .. 'F', -- Find surrounding (to the left)
        highlight = hotkey .. 'h', -- Highlight surrounding
        replace = hotkey .. 'r', -- Replace surrounding
        update_n_lines = hotkey .. 'n', -- Update `n_lines`

        suffix_last = 'l', -- Suffix to search with "prev" method
        suffix_next = 'n', -- Suffix to search with "next" method
      },
    }
    --
    -- require('mini.pick').setup()
    --
    -- local function get_globals()
    --   ---@type table
    --   local gvars = vim.fn.getcompletion('g:', 'var')
    --   local gvals = vim.tbl_map(function(key)
    --     return { key, vim.g[string.gsub(key, 'g:', '')] }
    --   end, gvars)
    --   MiniPick.start { source = {
    --     items = gvals,
    --   } }
    -- end
    --
    -- vim.keymap.set('n', '<leader>sv', get_globals, { desc = '[S]earch [g]lobals [v]ariables (g: variables)' })
    --
    -- local statusline = require 'mini.statusline'
    -- statusline.setup {
    --   use_icons = vim.g.have_nerd_font,
    --   content = {
    --     active = function()
    --       local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
    --       local git = MiniStatusline.section_git { trunc_width = 40 }
    --       local diff = MiniStatusline.section_diff { trunc_width = 75 }
    --       local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 }
    --       local lsp = MiniStatusline.section_lsp { trunc_width = 75 }
    --       local filename = MiniStatusline.section_filename { trunc_width = 140 }
    --       local fileinfo = MiniStatusline.section_fileinfo { trunc_width = 120 }
    --       local location = MiniStatusline.section_location { trunc_width = 200 }
    --       local search = MiniStatusline.section_searchcount { trunc_width = 75 }
    --       -- local macro = check_macro_recording()
    --
    --       return MiniStatusline.combine_groups {
    --         { hl = mode_hl, strings = { mode } },
    --         { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics } },
    --         '%<', -- Mark general truncate point
    --         { hl = 'MiniStatuslineFilename', strings = { filename } },
    --         '%=', -- End left alignment
    --         { hl = 'MiniStatuslineFileinfo', strings = { fileinfo, lsp } },
    --         { hl = mode_hl, strings = { search, '%2l:%-2v' } },
    --       }
    --     end,
    --   },
    -- }
    --
    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}
