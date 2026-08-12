if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/webhooked/kanso.nvim',
  'https://github.com/rebelot/kanagawa.nvim',
})

require('kanso').setup({
  background = { dark = 'ink', light = 'pearl' },
})

require('kanagawa').setup({
  compile = false,
})

local function dotfiles_theme()
  local out = vim.fn.system({ 'chezmoi', 'data', '--format', 'json' })
  if vim.v.shell_error ~= 0 then
    return 'kanagawa'
  end
  local ok, data = pcall(vim.json.decode, out)
  if ok and type(data.theme) == 'string' and data.theme ~= '' then
    return data.theme
  end
  return 'kanagawa'
end

local function default_colorscheme(family)
  if family == 'kanso' then
    return 'kanso'
  end
  if vim.o.background == 'light' then
    return 'kanagawa-lotus'
  end
  return 'kanagawa-dragon'
end

local function load_colorscheme()
  local path = vim.fn.stdpath('data') .. '/colorscheme.current'
  if vim.fn.filereadable(path) == 1 then
    local name = vim.trim(vim.fn.readfile(path)[1] or '')
    if name ~= '' and pcall(vim.cmd.colorscheme, name) then
      return
    end
  end
  vim.cmd.colorscheme(default_colorscheme(dotfiles_theme()))
end

load_colorscheme()
