---@module 'lazy.types'
---@type LazyPluginSpec[]
return {
  {
    'stevearc/overseer.nvim',
    cmd = {
      'OverseerOpen',
      'OverseerClose',
      'OverseerToggle',
      'OverseerSaveBundle',
      'OverseerLoadBundle',
      'OverseerDeleteBundle',
      'OverseerRunCmd',
      'OverseerRun',
      'OverseerInfo',
      'OverseerBuild',
      'OverseerQuickAction',
      'OverseerTaskAction',
      'OverseerClearCache',
    },
    ---@type overseer.Config
    opts = {
      -- dap = false,
      task_list = {
        bindings = {
          -- ['<C-h>'] = false,
          -- ['<C-j>'] = false,
          -- ['<C-k>'] = false,
          -- ['<C-l>'] = false,
          ['<Esc><Esc>'] = 'Close',
        },
      },
      task_launcher = {
        bindings = {
          n = {
            ['<Esc><Esc>'] = 'Cancel',
          },
        },
      },
      task_editor = {
        bindings = {
          n = {
            ['<Esc><Esc>'] = 'Cancel',
          },
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>o/",           "<cmd>OverseerToggle<cr>",      desc = "Task list" },
      { "<leader>o<space>",     "<cmd>OverseerRun<cr>",         desc = "Run task" },
      { "<leader>oq",           "<cmd>OverseerQuickAction<cr>", desc = "Action recent task" },
      { "<leader>o?",           "<cmd>OverseerInfo<cr>",        desc = "Overseer Info" },
      { "<leader>ob",           "<cmd>OverseerBuild<cr>",       desc = "Task builder" },
      { "<leader>ot",           "<cmd>OverseerTaskAction<cr>",  desc = "Task action" },
      { "<leader>o<backspace>", "<cmd>OverseerClearCache",      desc = "Clear cache?" },
    },
  },
  {
    'folke/which-key.nvim',
    optional = true,
    opts = {
      spec = {
        { '<leader>o', group = 'overseer' },
      },
    },
  },
  {
    'folke/edgy.nvim',
    optional = true,
    opts = function(_, opts)
      opts.right = opts.right or {}
      table.insert(opts.right, {
        title = 'Overseer',
        ft = 'OverseerList',
        open = function()
          require('overseer').open()
        end,
      })
    end,
  },
  -- {
  --   'nvim-neotest/neotest',
  --   optional = true,
  --   opts = function(_, opts)
  --     opts = opts or {}
  --     opts.consumers = opts.consumers or {}
  --     opts.consumers.overseer = require 'neotest.consumers.overseer'
  --   end,
  -- },
  {
    'mfussenegger/nvim-dap',
    optional = true,
    opts = function()
      require('overseer').enable_dap()
    end,
  },
}
