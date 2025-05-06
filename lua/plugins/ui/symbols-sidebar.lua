require 'lazy.types'
---@type LazyPluginSpec[]
return {
  {
    'oskarrrrrrr/symbols.nvim',
    opts = function()
      local r = require 'symbols.recipes'
      return require('symbols.config').prepare_config {
        r.DefaultFilters,
        r.AsciiSymbols,
        sidebar = {
          open_direction = 'try-right',
          hide_cursor = false,
          auto_peek = true,
          cursor_follow = true,
          close_on_goto = false,
          preview = {
            -- add a convenient keymap
            keymaps = { ['<cr>'] = 'goto-code' },
          },
        },
      }
    end,
    keys = function(_, _)
      -- Example keymaps below.

      -- async, needed for some keymaps
      -- local a = require 'symbols.async'

      return {
        {
          '\\s',
          '<cmd>Symbols<CR>',
          desc = 'Open the sidebar.',
        },

        -- {
        --   '\\S',
        --   '<cmd>SymbolsClose<CR>',
        --   desc = 'Close the sidebar.',
        -- },
        --
        -- {
        --   '<leader>s\\',
        --   a.sync(function()
        --     a.wait(Symbols.sidebar.open(0))
        --     Symbols.sidebar.view_set(0, 'search')
        --     Symbols.sidebar.focus(0)
        --   end),
        --   desc = "Search in the sidebar. Open the sidebar if it's closed.",
        -- },

        -- -- The next two mappings move the cursor up/down in the sidebar and peek the symbol
        -- -- without changing the focused window.
        --
        -- {
        --   '<C-k>',
        --   function()
        --     if not Symbols.sidebar.visible(0) then
        --       return
        --     end
        --     Symbols.sidebar.view_set(0, 'symbols')
        --     Symbols.sidebar.focus(0)
        --     local count = math.max(vim.v.count, 1)
        --     local pos = vim.api.nvim_win_get_cursor(0)
        --     local new_cursor_row = math.max(1, pos[1] - count)
        --     pcall(vim.api.nvim_win_set_cursor, 0, { new_cursor_row, pos[2] })
        --     Symbols.sidebar.symbols.current_peek(0)
        --     Symbols.sidebar.focus_source(0)
        --   end,
        -- },
        --
        -- {
        --   '<C-j>',
        --   function()
        --     if not Symbols.sidebar.visible(0) then
        --       return
        --     end
        --     Symbols.sidebar.view_set(0, 'symbols')
        --     Symbols.sidebar.focus(0)
        --     local win = Symbols.sidebar.win(0)
        --     local sidebar_line_count = vim.fn.line('$', win)
        --     local pos = vim.api.nvim_win_get_cursor(0)
        --     local count = math.max(vim.v.count, 1)
        --     local new_cursor_row = math.min(sidebar_line_count, pos[1] + count)
        --     pcall(vim.api.nvim_win_set_cursor, 0, { new_cursor_row, pos[2] })
        --     Symbols.sidebar.symbols.current_peek(0)
        --     Symbols.sidebar.focus_source(0)
        --   end,
        -- },

        -- Below are 8 mappings (zm, Zm, zr, zR, zo, zO, zc, zC) for managing folds.
        -- They modify the sidebar folds and regular vim folds at the same time.
        -- In some cases the behavior might be surprising, for instance, when you
        -- use folds that do not correspond to symbols in the sidebar.

        {
          'zm',
          function()
            if Symbols.sidebar.visible(0) then
              local count = math.max(vim.v.count, 1)
              Symbols.sidebar.symbols.fold(0, count)
            end
            pcall(vim.api.nvim_cmd, 'normal!', 'zm')
          end,
        },

        {
          'zM',
          function()
            if Symbols.sidebar.visible(0) then
              Symbols.sidebar.symbols.fold_all(0)
            end
            pcall(vim.api.nvim_cmd, 'normal! zM')
          end,
        },

        {
          'zr',
          function()
            if Symbols.sidebar.visible(0) then
              local count = math.max(vim.v.count, 1)
              Symbols.sidebar.symbols.unfold(0, count)
            end
            pcall(vim.api.nvim_cmd, 'normal! zr')
          end,
        },

        {
          'zR',
          function()
            local sb = Symbols.sidebar.get()
            if Symbols.sidebar.visible(sb) then
              Symbols.sidebar.symbols.unfold_all(sb)
            end
            pcall(vim.api.nvim_cmd, 'normal! zR')
          end,
        },

        {
          'zo',
          function()
            local sb = Symbols.sidebar.get()
            if Symbols.sidebar.visible(sb) then
              Symbols.sidebar.symbols.current_unfold(sb)
            end
            pcall(vim.api.nvim_cmd, 'normal! zo')
          end,
        },

        {
          'zO',
          function()
            local sb = Symbols.sidebar.get()
            if Symbols.sidebar.visible(sb) then
              Symbols.sidebar.symbols.current_unfold(sb, true)
            end
            pcall(vim.api.nvim_cmd, 'normal! zO')
          end,
        },

        {
          'zc',
          function()
            local sb = Symbols.sidebar.get()
            if Symbols.sidebar.visible(sb) then
              if Symbols.sidebar.symbols.current_visible_children(sb) == 0 or Symbols.sidebar.symbols.current_folded(sb) then
                Symbols.sidebar.symbols.goto_parent(sb)
              else
                Symbols.sidebar.symbols.current_fold(sb)
              end
            end
            pcall(vim.api.nvim_cmd, 'normal! zc')
          end,
        },

        {
          'zC',
          function()
            local sb = Symbols.sidebar.get()
            if Symbols.sidebar.visible(sb) then
              Symbols.sidebar.symbols.current_fold(sb, true)
            end
            pcall(vim.api.nvim_cmd, 'normal! zC')
          end,
        },
      }
    end,
  },
  {
    'folke/edgy.nvim',
    dependencies = {
      'oskarrrrrrr/symbols.nvim',
    },
    ---@type Edgy.View.Opts[]
    opts = {
      right = {
        {
          title = function()
            local buf_name = vim.api.nvim_buf_get_name(0) or '[No Name]'
            return vim.fn.fnamemodify(buf_name, ':t')
          end,
          ft = 'SymbolsSidebar',
          open = 'SymbolsOpen',
          pinned = true,
        },
      },
    },
    keys = {
      {
        '<leader>er',
        function()
          require('edgy').toggle 'right'
        end,
        desc = '[E]dgy: [r]ight panel',
      },
      -- Show current symbol in the sidebar (unfolds symbols if needed).
      -- Opens the sidebar if it's closed. Especially useful with deeply
      -- nested symbols, e.g. when using with JSON files.
      {
        'gs',
        function()
          local edg = require 'edgy'
          edg.open 'right'
          edg.goto_main()

          require('edgy').select 'right'
        end,
        desc = 'Show symbol in outline',
      },
    },
  },
}
