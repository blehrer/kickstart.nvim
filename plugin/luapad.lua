if vim.g.vscode then return end

vim.pack.add({ 'https://github.com/rafcamlet/nvim-luapad' })

require('luapad').setup({})

vim.keymap.set('n', '<leader>.', function()
  vim.ui.select({
    'New',
    'Toggle (current buffer)',
    'Attach to buffer',
    'Detach from buffer',
  }, { prompt = 'Luapad Actions' }, function(choice)
    if choice == 'New' then
      require('luapad').init()
    elseif choice == 'Toggle (current buffer)' then
      require('luapad').toggle()
    elseif choice == 'Attach to buffer' then
      require('luapad').attach()
    elseif choice == 'Detach from buffer' then
      require('luapad').detach()
    end
  end)
end, { desc = 'Luapad REPL' })
