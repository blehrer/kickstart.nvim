--- Alt+1 LSP context: doc hover split + local symbols around the current window.
local M = {}

local hover = require('config.hover')

local symbols_opts = {
  mode = 'symbols',
  pinned = true,
  focus = false,
  auto_preview = false,
  win = {
    type = 'split',
    relative = 'win',
    position = 'right',
    size = 0.22,
  },
}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local state = {
  main_win = nil,
}

function M.is_open()
  return hover.is_open() or require('trouble').is_open({ mode = 'symbols' })
end

function M.close()
  hover.close()
  require('trouble').close({ mode = 'symbols' })
  state.main_win = nil
end

function M.open(main_win)
  main_win = main_win or vim.api.nvim_get_current_win()
  state.main_win = main_win

  symbols_opts.win.win = main_win
  require('trouble').open(vim.tbl_extend('force', symbols_opts, { new = true }))
  hover.open(main_win)

  if valid_win(main_win) then
    vim.api.nvim_set_current_win(main_win)
  end
end

function M.toggle()
  if M.is_open() then
    local main_win = state.main_win
    M.close()
    if valid_win(main_win) then
      vim.api.nvim_set_current_win(main_win)
    end
    return
  end

  M.open()
end

function M.setup_keymaps()
  vim.keymap.set('n', '<A-1>', M.toggle, { desc = 'LSP panels (docs + symbols)' })
end

return M
