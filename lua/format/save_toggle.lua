local M = {}

local STATE_DIR = vim.fn.stdpath('config') .. '/state'
local STATE_FILE = STATE_DIR .. '/format-on-save'

local function persist(enabled)
  vim.fn.mkdir(STATE_DIR, 'p')
  local f = io.open(STATE_FILE, 'w')
  if not f then
    return
  end
  f:write(enabled and '1\n' or '0\n')
  f:close()
end

local function read_persisted()
  local f = io.open(STATE_FILE, 'r')
  if not f then
    return false
  end
  local line = f:read('l')
  f:close()
  return line == '1'
end

function M.enabled()
  return vim.g.format_on_save == true
end

function M.apply(enabled)
  vim.g.format_on_save = enabled
  vim.g.editorconfig = enabled

  if vim.g.vscode then
    local ok, vscode = pcall(require, 'vscode')
    if ok then
      pcall(vscode.update_config, 'editor.formatOnSave', enabled)
      pcall(vscode.update_config, 'editorconfig.enable', enabled)
    end
  end

  persist(enabled)
end

function M.notify(enabled)
  vim.notify(
    enabled and 'Format on save + EditorConfig: on' or 'Format on save + EditorConfig: off',
    vim.log.levels.INFO
  )
end

function M.toggle()
  local next = not M.enabled()
  M.apply(next)
  M.notify(next)
  return next
end

function M.setup()
  vim.g.format_full_file = nil
  M.apply(read_persisted())
end

local function clear_legacy_maps()
  for _, mode in ipairs({ 'n', 'v', 'x', 's', 'o', 'i' }) do
    pcall(vim.keymap.del, mode, '<leader>ufh')
  end
end

function M.setup_toggle()
  clear_legacy_maps()

  local opts = { desc = 'Toggle format on save + EditorConfig', nowait = true }

  if vim.g.vscode then
    vim.keymap.set('n', '<leader>uf', M.toggle, opts)
    return
  end

  Snacks.toggle({
    name = 'Format on save + EditorConfig',
    id = 'format_on_save',
    get = M.enabled,
    set = function(state)
      local was = M.enabled()
      M.apply(state)
      if was ~= state then
        M.notify(state)
      end
    end,
  }):map('<leader>uf', opts)
end

return M
