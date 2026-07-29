-- -- Expand 'cc' into 'CodeCompanion' in the command line
-- vim.cmd [[cab cc CodeCompanion]]
--
-- ---@module 'lazy.types'
-- ---@type LazyPluginSpec
-- return {
--   'olimorris/codecompanion.nvim',
--   version = '^19.0.0',
--   ---@type LazyKeysSpec[]
--   opts = {
--     interactions = {
--       chat = {
--         adapter = 'cursor_cli',
--       },
--       inline = {
--         adapter = 'cursor_cli',
--       },
--       cmd = {
--         adapter = 'cursor_cli',
--       },
--       background = {
--         adapter = 'cursor_cli',
--       },
--     },
--     adapters = {
--       cursor_cli = function()
--         require('codecompanion.adpaters').extends('cursor_cli', {
--           env = {
--             api_key = { vim.cmd '!op read op://Employee/CURSOR_TOKEN/token' },
--           },
--         })
--       end,
--     },
--   },
--   dependencies = {
--     'nvim-lua/plenary.nvim',
--     'nvim-treesitter/nvim-treesitter',
--     'ravitemer/mcphub.nvim',
--     {
--       'MeanderingProgrammer/render-markdown.nvim',
--       ft = { 'markdown', 'codecompanion' },
--     },
--
--     {
--       'HakonHarnes/img-clip.nvim',
--       opts = {
--         filetypes = {
--           codecompanion = {
--             prompt_for_file_name = false,
--             template = '[Image]($FILE_PATH)',
--             use_absolute_path = true,
--           },
--         },
--       },
--     },
--   },
--   keys = {
--     { '<C-a>', '<cmd>CodeCompanionActions<cr>', { noremap = true, silent = true } },
--     { '<LocalLeader>a', '<cmd>CodeCompanionChat Toggle<cr>', { noremap = true, silent = true } },
--     { 'ga', '<cmd>CodeCompanionChat Add<cr>', { noremap = true, silent = true } },
--   },
-- }

return {
  'folke/sidekick.nvim',
  opts = {
    -- add any options here
    cli = {
      mux = {
        backend = 'zellij',
        enabled = false,
      },
    },
  },
  keys = {
    {
      '<tab>',
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require('sidekick').nes_jump_or_apply() then
          return '<Tab>' -- fallback to normal tab
        end
      end,
      expr = true,
      desc = 'Goto/Apply Next Edit Suggestion',
    },
    {
      '<c-.>',
      function()
        require('sidekick.cli').focus()
      end,
      desc = 'Sidekick Focus',
      mode = { 'n', 't', 'i', 'x' },
    },
    {
      '<leader>aa',
      function()
        require('sidekick.cli').toggle()
      end,
      desc = 'Sidekick Toggle CLI',
    },
    {
      '<leader>as',
      function()
        require('sidekick.cli').select()
      end,
      -- Or to select only installed tools:
      -- require("sidekick.cli").select({ filter = { installed = true } })
      desc = 'Select CLI',
    },
    {
      '<leader>ad',
      function()
        require('sidekick.cli').close()
      end,
      desc = 'Detach a CLI Session',
    },
    {
      '<leader>at',
      function()
        require('sidekick.cli').send { msg = '{this}' }
      end,
      mode = { 'x', 'n' },
      desc = 'Send This',
    },
    {
      '<leader>af',
      function()
        require('sidekick.cli').send { msg = '{file}' }
      end,
      desc = 'Send File',
    },
    {
      '<leader>av',
      function()
        require('sidekick.cli').send { msg = '{selection}' }
      end,
      mode = { 'x' },
      desc = 'Send Visual Selection',
    },
    {
      '<leader>ap',
      function()
        require('sidekick.cli').prompt()
      end,
      mode = { 'n', 'x' },
      desc = 'Sidekick Select Prompt',
    },

    {
      '<leader>ac',
      function()
        require('sidekick.cli').toggle { 'agent', focus = true }
      end,
      desc = 'Sidekick Cursor Agent',
    },
  },
}
