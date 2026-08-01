vim.cmd.cabbrev('w!!', 'w !SUDO_ASKPASS="/usr/bin/pass $USER" sudo --askpass tee % > /dev/null')

-- <Esc> clears search highlight only (plugin/30-snacks.lua).
-- Notifications: <leader>un history · <leader>uN dismiss
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<leader>w', '<cmd>w<cr>', { desc = '[W]rite' })
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>w<cr>', { desc = '[W]rite' })
vim.keymap.set({ 'n', 'i', 'v' }, '<D-s>', '<cmd>w<cr>', { desc = '[W]rite' })
vim.keymap.set('n', '<leader>q', ':q<cr>', { desc = '[Q]uit' })
vim.keymap.set('n', '<A-j>', 'a<cr><esc>k$', { desc = 'Split line below' })
vim.keymap.set('n', '<C-j>', 'a<cr><esc>k$', { desc = 'Split line below' })

vim.keymap.set('n', '<leader>>', ':lua ', { desc = 'Lua prompt' })

-- Guard against plugins remapping <Tab> in insert mode out from under us
vim.keymap.set('i', '<Tab>', '<Tab>')

if not vim.g.vscode then
  vim.keymap.set('n', '<leader>re', '<cmd>restart<cr>', { desc = 'Restart Neovim' })
end

vim.keymap.set({ 'n', 'v' }, 'gl', function()
  vim.diagnostic.open_float({ source = true })
end, { desc = 'Diagnostics float' })

vim.keymap.set('n', 'g<', function()
  vim.diagnostic.setqflist({ open = true })
end, { desc = 'Diagnostics to quickfix' })

-- Visual selection → project grep (Snacks; Cursor uses keybindings.json for <leader>sg)
if not vim.g.vscode then
vim.keymap.set('v', '<leader>sg', function()
  local srow, scol = vim.fn.line('v'), vim.fn.col('v')
  local erow, ecol = vim.fn.line('.'), vim.fn.col('.')
  local region = vim.region(0, { srow - 1, scol - 1 }, { erow - 1, ecol }, 'v', true)

  local lines = {}
  for row, cols in pairs(region) do
    local line_text = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ''
    table.insert(lines, string.sub(line_text, cols[1] + 1, cols[2]))
  end
  local selection = table.concat(lines, '\n')

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)

  if selection ~= '' then
    Snacks.picker.grep({ search = selection, live = true })
  end
end, { desc = 'Search project for visual selection' })
end
