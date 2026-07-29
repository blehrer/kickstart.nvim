vim.pack.add({ 'https://github.com/folke/sidekick.nvim' })

require('sidekick').setup({
  cli = {
    mux = { backend = 'zellij', enabled = false },
  },
})

vim.keymap.set('n', '<Tab>', function()
  if not require('sidekick').nes_jump_or_apply() then
    return '<Tab>'
  end
end, { expr = true, desc = 'NES jump/apply' })

vim.keymap.set({ 'n', 't', 'i' }, '<C-.>', function()
  require('sidekick.cli').focus()
end, { desc = 'Sidekick focus CLI' })

vim.keymap.set('n', '<leader>aa', function()
  require('sidekick.cli').toggle()
end, { desc = 'Sidekick toggle CLI' })

vim.keymap.set('n', '<leader>as', function()
  require('sidekick.cli').select()
end, { desc = 'Sidekick select CLI' })
