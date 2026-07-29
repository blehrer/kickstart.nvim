vim.cmd.cabbrev('w!!', 'w !SUDO_ASKPASS="/usr/bin/pass $USER" sudo --askpass tee % > /dev/null')
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

vim.keymap.set('n', '<leader>w', '<cmd>w<cr>', { desc = '[W]rite' })
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>w<cr>', { desc = '[W]rite' })
vim.keymap.set({ 'n', 'i', 'v' }, '<D-s>', '<cmd>w<cr>', { desc = '[W]rite' })

vim.keymap.set('n', '<leader>q', ':q<cr>', { desc = '[Q]uit' })

vim.keymap.set('n', '<A-j>', 'a<cr><esc>k$', { desc = 'Split lines (opposite of `shift+j`)' })

vim.keymap.set('n', '<C-j>', 'a<cr><esc>k$', { desc = 'Split lines (opposite of `shift+j`)' })

vim.keymap.set('n', '<F18>', function()
  local old_name = vim.fn.expand '%'
  local new_name = vim.fn.input('New file name: ', vim.fn.expand '%', 'file')
  if new_name ~= '' and new_name ~= old_name then
    vim.fn.execute(':saveas ' + new_name)
    vim.fn.execute(':silent !rm ' + old_name)
  end
end, { desc = 'Rename file (f18 is r on the intellij layer)' })

vim.keymap.set('n', '<leader>l', ':Lazy<cr>', { desc = '[L]azy plugin manager' })

vim.keymap.set('n', '<leader>' .. '>', ':lua ', { desc = 'Lua prompt' })

-- @ThePrimeagen
vim.keymap.set({ 'v', 'n' }, '<leader>rw', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = '[R]eplace [w]ord under cursor' })

-- make sure tab is unmapped
vim.keymap.set({ 'i' }, '<Tab>', '<Tab>')

vim.keymap.set('n', '<leader>re', '<cmd>restart<cr>', { desc = 'Restart Neovim' })
vim.keymap.set({ 'n', 'v' }, 'gl', function()
  vim.diagnostic.open_float {
    source = true,
  }
end)
vim.keymap.set('n', 'g<', function()
  vim.diagnostic.setqflist { open = true }
end, { desc = 'Diagnostics to quickfix list' })

-- Search project for exact visual selection using Snacks.picker
vim.keymap.set('v', '<leader>sg', function()
  -- 1. Get visual selection marks correctly
  local srow, scol = vim.fn.line 'v', vim.fn.col 'v'
  local erow, ecol = vim.fn.line '.', vim.fn.col '.'

  -- 2. Use vim.region to handle multi-byte UTF-8 boundaries cleanly
  -- This creates a safe structure that avoids slicing multi-byte characters into hex chunks
  local region = vim.region(0, { srow - 1, scol - 1 }, { erow - 1, ecol }, 'v', true)

  local lines = {}
  for row, cols in pairs(region) do
    local line_text = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ''
    -- Slice the line using exact byte regions resolved by vim.region
    table.insert(lines, string.sub(line_text, cols[1] + 1, cols[2]))
  end
  local selection = table.concat(lines, '\n')

  -- 3. Clear visual highlight state before opening the picker UI
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)

  -- 4. Pass the clean string to Snacks picker
  if selection and selection ~= '' then
    Snacks.picker.grep {
      search = selection, -- Pre-fills the global project search field
      live = true, -- Allows you to modify the search query live
    }
  end
end, { desc = 'Search project for visual selection with Snacks' })

return {}
