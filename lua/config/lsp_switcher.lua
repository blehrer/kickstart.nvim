--- Buffer/filetype LSP switcher (<leader>uL): toggle compatible LSP servers on/off for the active buffer.
local M = {}

local function candidate_names()
  local seen = {}
  local names = {}
  local function add(name)
    if name and name ~= '' and not seen[name] then
      seen[name] = true
      names[#names + 1] = name
    end
  end

  for _, name in ipairs(require('config.lsp').ensure_installed or {}) do
    add(name)
  end
  local ok, mlsp = pcall(require, 'mason-lspconfig')
  if ok and mlsp.get_installed_servers then
    for _, name in ipairs(mlsp.get_installed_servers()) do
      add(name)
    end
  end
  for _, c in ipairs(vim.lsp.get_clients()) do
    add(c.name)
  end
  table.sort(names)
  return names
end

local function matches_filetype(cfg, ft)
  if not ft or ft == '' then
    return false
  end
  local fts = cfg and cfg.filetypes
  if type(fts) ~= 'table' then
    return false
  end
  if vim.tbl_contains(fts, ft) then
    return true
  end
  local base = ft:match('^([^%.]+)')
  return base ~= nil and vim.tbl_contains(fts, base)
end

---@param bufnr integer
---@return table[]
function M.discover_for_buf(bufnr)
  bufnr = (not bufnr or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local ft = vim.bo[bufnr].filetype
  local attached_by_name = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    attached_by_name[c.name] = c
  end

  local excluded = {
    kotlin_language_server = true,
    stylua = true,
    gradle_ls = true,
  }

  local out = {}
  for _, name in ipairs(candidate_names()) do
    local cfg = vim.lsp.config[name]
    local attached = attached_by_name[name]
    if attached or ( not excluded[name] and matches_filetype(cfg, ft) ) then
      out[#out + 1] = {
        name = name,
        attached = attached ~= nil,
        client_id = attached and attached.id or nil,
        enabled = vim.lsp.is_enabled(name),
        filetypes = (cfg and cfg.filetypes) or {},
      }
    end
  end
  return out
end

---@param bufnr integer
---@param name string
---@return boolean next_attached
function M.toggle_server(bufnr, name)
  bufnr = (not bufnr or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local attached = vim.lsp.get_clients({ bufnr = bufnr, name = name })
  if #attached > 0 then
    vim.lsp.enable(name, false)
    for _, c in ipairs(vim.lsp.get_clients({ name = name })) do
      vim.lsp.stop_client(c.id, true)
    end
    return false
  end

  vim.lsp.enable(name, true)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd.doautoall('nvim.lsp.enable FileType')
    end)
  end
  return true
end

---@param bufnr integer
---@param keep_name string
function M.solo_server(bufnr, keep_name)
  bufnr = (not bufnr or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  for _, item in ipairs(M.discover_for_buf(bufnr)) do
    if item.name ~= keep_name and (item.attached or item.enabled) then
      vim.lsp.enable(item.name, false)
      for _, c in ipairs(vim.lsp.get_clients({ name = item.name })) do
        vim.lsp.stop_client(c.id, true)
      end
    end
  end
  vim.lsp.enable(keep_name, true)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd.doautoall('nvim.lsp.enable FileType')
    end)
  end
end

local function format_item(item)
  local a = Snacks.picker.util.align
  local mark = item.attached and '󰄲' or ' '
  local state = item.attached and 'attached' or (item.enabled and 'enabled (detached)' or 'disabled')
  return {
    { a(mark, 2) },
    { a(item.name, 20) },
    { ' ' },
    { state, item.attached and 'SnacksPickerMatch' or 'SnacksPickerDimmed' },
  }
end

function M.open(bufnr)
  bufnr = (not bufnr or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local ft = vim.bo[bufnr].filetype
  local initial = M.discover_for_buf(bufnr)
  if #initial == 0 then
    vim.notify(('No LSP servers registered for filetype %q'):format(ft), vim.log.levels.INFO)
    return
  end

  local function finder()
    local items = {}
    for _, s in ipairs(M.discover_for_buf(bufnr)) do
      items[#items + 1] = {
        name = s.name,
        attached = s.attached,
        enabled = s.enabled,
        text = ('%s %s'):format(s.attached and '[on]' or '[off]', s.name),
      }
    end
    return items
  end

  Snacks.picker({
    title = ('Buffer LSP Switcher (%s)'):format(ft ~= '' and ft or 'no ft'),
    finder = finder,
    format = format_item,
    confirm = function(picker, item)
      if not item then
        return
      end
      local on = M.toggle_server(bufnr, item.name)
      vim.notify(('LSP %s %s'):format(item.name, on and 'enabled' or 'paused'), vim.log.levels.INFO)
      vim.defer_fn(function()
        if picker and not picker.closed then
          picker:refresh()
        end
      end, 150)
    end,
    actions = {
      toggle = function(picker)
        local item = picker:current()
        if not item then
          return
        end
        local on = M.toggle_server(bufnr, item.name)
        vim.notify(('LSP %s %s'):format(item.name, on and 'enabled' or 'paused'), vim.log.levels.INFO)
        vim.defer_fn(function()
          if picker and not picker.closed then
            picker:refresh()
          end
        end, 150)
      end,
      solo = function(picker)
        local item = picker:current()
        if not item then
          return
        end
        M.solo_server(bufnr, item.name)
        vim.notify(('Soloed LSP %s for %s (muted others)'):format(item.name, ft), vim.log.levels.INFO)
        vim.defer_fn(function()
          if picker and not picker.closed then
            picker:refresh()
          end
        end, 150)
      end,
    },
    win = {
      input = {
        keys = {
          ['<Tab>'] = { 'toggle', mode = { 'n', 'i' }, desc = 'Toggle server on/off' },
          ['<C-s>'] = { 'solo', mode = { 'n', 'i' }, desc = 'Solo this server (mute others)' },
          s = { 'solo', mode = 'n', desc = 'Solo this server (mute others)' },
        },
      },
      list = {
        keys = {
          ['<Tab>'] = { 'toggle', mode = 'n', desc = 'Toggle server on/off' },
          s = { 'solo', mode = 'n', desc = 'Solo this server (mute others)' },
        },
      },
    },
  })
end

return M
