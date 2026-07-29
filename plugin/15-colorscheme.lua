vim.pack.add({
  'https://github.com/webhooked/kanso.nvim',
  'https://github.com/rebelot/kanagawa.nvim',
})

require('kanso').setup({
  background = { dark = 'ink', light = 'pearl' },
})

local function load_saved_colorscheme()
  local path = vim.fn.stdpath('data') .. '/colorscheme.current'
  if vim.fn.filereadable(path) == 1 then
    local name = vim.trim(vim.fn.readfile(path)[1] or '')
    if name ~= '' and pcall(vim.cmd.colorscheme, name) then
      return
    end
  end
  vim.cmd.colorscheme('kanso')
end

load_saved_colorscheme()
