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
  local data_path = vim.env.HOME .. '/.local/share/chezmoi/home/.chezmoidata.toml'
  if vim.fn.filereadable(data_path) == 1 then
    for _, line in ipairs(vim.fn.readfile(data_path)) do
      local theme = line:match('^theme%s*=%s*"(.-)"')
      if theme then
        return theme
      end
    end
  end

  if vim.fn.executable('chezmoi') == 1 then
    local out = vim.fn.system({ 'chezmoi', 'data', '--format', 'json' })
    if vim.v.shell_error == 0 then
      local ok, data = pcall(vim.json.decode, out)
      if ok and type(data.theme) == 'string' and data.theme ~= '' then
        return data.theme
      end
    end
  end

  return 'kanagawa'
end

local function scheme_family(name)
  if name:match('^kanso') then
    return 'kanso'
  end
  if name:match('^kanagawa') then
    return 'kanagawa'
  end
  return nil
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
  local family = dotfiles_theme()
  local path = vim.fn.stdpath('data') .. '/colorscheme.current'

  if vim.fn.filereadable(path) == 1 then
    local name = vim.trim(vim.fn.readfile(path)[1] or '')
    if name ~= '' and scheme_family(name) == family and pcall(vim.cmd.colorscheme, name) then
      return
    end
  end

  vim.cmd.colorscheme(default_colorscheme(family))
end

load_colorscheme()
