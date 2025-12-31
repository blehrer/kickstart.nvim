-- Adds git related signs to the gutter, as well as utilities for managing changes
---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'lewis6991/gitsigns.nvim',
  ---@module 'gitsigns'
  ---@type Gitsigns.Config
  opts = {
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, { desc = 'Jump to next git [c]hange' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, { desc = 'Jump to previous git [c]hange' })

      -- Actions
      -- visual mode
      map('v', '<leader>ga', function()
        gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = '[g]it [a]dd/stage hunk' })
      map('v', '<leader>gr', function()
        gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = '[g]it [r]eset hunk' })
      -- normal mode
      map('n', '<leader>ga', gitsigns.stage_hunk, { desc = '[g]it [a]dd/stage hunk' })
      map('n', '<leader>gr', gitsigns.reset_hunk, { desc = '[g]it [r]eset hunk' })
      map('n', '<leader>gA', gitsigns.stage_buffer, { desc = '[g]it [A]dd/stage buffer' })
      map('n', '<leader>gu', gitsigns.stage_hunk, { desc = '[g]it [u]ndo add/stage hunk' })
      map('n', '<leader>gR', gitsigns.reset_buffer, { desc = '[g]it [R]eset buffer' })
      map('n', '<leader>gp', gitsigns.preview_hunk, { desc = '[g]it [p]review hunk' })
      map('n', '<leader>gb', gitsigns.blame_line, { desc = '[g]it [b]lame line' })
      map('n', '<leader>gd', gitsigns.diffthis, { desc = '[g]it [d]iff against index' })
      map('n', '<leader>gD', function()
        gitsigns.diffthis '@'
      end, { desc = '[g]it [D]iff against last commit' })
      -- Toggles
      map('n', '<leader>gtb', gitsigns.toggle_current_line_blame, { desc = '[g]it [t]oggle show [b]lame line' })
      map('n', '<leader>gtd', gitsigns.preview_hunk_inline, { desc = '[g]it [t]oggle show [d]eleted' })
    end,
  },
}
