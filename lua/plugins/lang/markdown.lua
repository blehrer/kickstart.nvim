local md_plugins = {}

if #vim.fn.exepath 'deno' > 0 then
  vim.list_extend(md_plugins, {
    'toppair/peek.nvim',
    event = { 'VeryLazy' },
    build = 'deno task --quiet build:fast',
    config = function()
      require('peek').setup()
      vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
      vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})
      vim.api.nvim_create_user_command('TogglePeek', function()
        local peek = require 'peek'
        if peek.is_open() then
          peek.close()
        else
          peek.open()
        end
      end, { desc = 'Toggle markdown preview (peek.nvim)' })
    end,
  })
end

local cmd = function(key)
  return vim.keycode('<D-%s>'):format(key)
end

vim.list_extend(md_plugins, {
  {
    'antonk52/markdowny.nvim',
    ft = 'markdown',
    opts = { filetypes = { 'markdown' } },
    keys = {
      { cmd 'b', ":lua require('markdowny').bold()<cr>", mode = 'v', buffer = 0, desc = 'toggle bold' },
      { cmd 'i', ":lua require('markdowny').italic()<cr>", mode = 'v', buffer = 0, desc = 'toggle italics' },
      { cmd 'k', ":lua require('markdowny').link()<cr>", mode = 'v', buffer = 0, desc = 'toggle link' },
      {
        cmd 'e',
        ":lua require('markdowny').code()<cr>",
        mode = 'v',
        buffer = 0,
        desc = 'toggle code ticks',
      },
    },
  },
  {

    {
      'MeanderingProgrammer/render-markdown.nvim',
      dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },
      opts = {
        -- Ensures the renderer runs even when a buffer is inside a diff window
        file_types = { 'markdown', 'vimwiki', 'DiffviewFiles' },
      },
    },

    {
      'sindrets/diffview.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' },
      config = function()
        require('diffview').setup {
          hooks = {
            -- Automatically force concealment and markdown rendering when viewing a diff
            diff_buf_read = function(bufnr)
              if vim.bo[bufnr].filetype == 'markdown' then
                vim.wo.conceallevel = 2
                vim.wo.concealcursor = 'nc'
              end
            end,
          },
        }
      end,
    },
  },
})

return md_plugins
