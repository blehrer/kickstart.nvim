---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'rafcamlet/nvim-luapad',
  lazy = true,
  opts = {},
  keys = {
    {
      '<leader>.',
      function()
        vim.ui.select({
          'New',
          'Toggle (current buffer)',
          'Attach to buffer',
          'Detach from buffer',
        }, {
          prompt = 'Luapad Actions',
        }, function(choice)
          if choice == 'New' then
            require('luapad').init()
          elseif choice == 'Toggle (current buffer)' then
            require('luapad').toggle()
          elseif choice == 'Attach to buffer' then
            require('luapad').attach()
          elseif choice == 'Detach from buffer' then
            require('luapad').dettach()
          else
            vim.notify(('"%s" not yet written'):format(choice))
          end
        end)
      end,
    },
  },
}
