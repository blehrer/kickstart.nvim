return {
  -- Keymaps are automatically loaded on the VeryLazy event
  -- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
  -- Add any additional keymaps here

  -- [[ Basic Keymaps ]]
  --  See `:help vim.keymap.set()`

  -- Clear highlights on search when pressing <Esc> in normal mode
  --  See `:help hlsearch`
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>'),

  -- Diagnostic keymaps
  -- vim.keymap.set('n', '<leader>x', vim.diagnostic.setloclist, { desc = 'Open diagnostic Quickfi[x] list' }),

  -- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
  -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
  -- is not what someone will guess without a bit more experience.
  --
  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
  -- or just use <C-\><C-n> to exit terminal mode
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' }),

  -- TIP: Disable arrow keys in normal mode
  -- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
  -- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
  -- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
  -- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

  -- Keybinds to make split navigation easier.
  --  Use CTRL+<hjkl> to switch between windows
  --
  --  See `:help wincmd` for a list of all window commands
  -- vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  -- vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  -- vim.keymap.set('n', '<C-w>j', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  -- vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- [[ Basic Autocommands ]]
  --  See `:help lua-guide-autocommands`

  -- Highlight when yanking (copying) text
  --  Try it with `yap` in normal mode
  --  See `:help vim.highlight.on_yank()`
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
      vim.highlight.on_yank()
    end,
  }),

  vim.cmd.cabbrev('w!!', 'w !SUDO_ASKPASS="/usr/bin/pass $USER" sudo --askpass tee % > /dev/null'),

  vim.keymap.set('n', '<leader>w', ':w<cr>', { desc = '[W]rite' }),

  vim.keymap.set('n', '<leader>q', ':q<cr>', { desc = '[Q]uit' }),

  vim.keymap.set('n', '<A-j>', 'a<cr><esc>k$', { desc = 'Split lines (opposite of `shift+j`)' }),

  vim.keymap.set('n', '<C-j>', 'a<cr><esc>k$', { desc = 'Split lines (opposite of `shift+j`)' }),

  vim.keymap.set('n', '<F18>', function()
    local old_name = vim.fn.expand '%'
    local new_name = vim.fn.input('New file name: ', vim.fn.expand '%', 'file')
    if new_name ~= '' and new_name ~= old_name then
      vim.fn.execute(':saveas ' + new_name)
      vim.fn.execute(':silent !rm ' + old_name)
    end
  end, { desc = 'Rename file (f18 is r on the intellij layer)' }),

  vim.keymap.set('n', '<leader>l', ':Lazy<cr>', { desc = '[L]azy plugin manager' }),

  vim.keymap.set('n', '-', ':Oil<cr>', { desc = 'Edit directory with oil.nvim' }),

  vim.keymap.set('n', '<leader>>', ':lua ', { desc = 'Lua prompt' }),

  -- @ThePrimeagen
  vim.keymap.set({ 'v', 'n' }, '<leader>rw', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = '[R]eplace [w]ord under cursor' }),
}
