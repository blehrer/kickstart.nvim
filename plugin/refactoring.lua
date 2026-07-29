vim.pack.add({
  'https://github.com/lewis6991/async.nvim',
  'https://github.com/ThePrimeagen/refactoring.nvim',
  'https://github.com/mawkler/refjump.nvim',
  'https://github.com/catgoose/nvim-colorizer.lua',
  'https://github.com/chrisgrieser/nvim-scissors',
})

require('refjump').setup({
  integrations = { demicolon = { enable = false } },
})

require('colorizer').setup({
  user_default_options = {
    names = false,
    tailwind = true,
    xterm = true,
  },
})

require('scissors').setup({
  snippetDir = vim.fs.joinpath(vim.fn.stdpath('config'), 'snippets', 'vscode'),
  snippetSelection = { picker = 'snacks' },
})

vim.keymap.set('n', '<leader>cse', function()
  require('scissors').editSnippet()
end, { desc = 'Edit snippet' })

vim.keymap.set({ 'n', 'x' }, '<leader>csa', function()
  require('scissors').addNewSnippet()
end, { desc = 'Add snippet' })

local function refactor_pick()
  vim.ui.select(require('refactoring').get_refactors(), { prompt = 'Refactor' }, function(choice)
    if choice then
      require('refactoring').refactor(choice)
    end
  end)
end

vim.keymap.set('v', '<leader>rs', refactor_pick, { desc = 'Refactor (picker)' })
vim.keymap.set('v', '<leader>rf', function()
  require('refactoring').refactor('Extract Function')
end, { desc = 'Extract function' })
vim.keymap.set('v', '<leader>rx', function()
  require('refactoring').refactor('Extract Variable')
end, { desc = 'Extract variable' })
