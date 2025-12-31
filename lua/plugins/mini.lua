---@module 'lazy.types'
---@type LazyPluginSpec
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

    local hotkey = '<localleader>s'
    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - <hotkey>aiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - <hotkey>d'   - [S]urround [D]elete [']quotes
    -- - <hotkey>r)'  - [S]urround [R]eplace [)] [']
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
  end,
}
