local M = {}

--- Any diff window in the current tab means we're in a diff/merge layout.
function M.in_diff_session()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.wo[win].diff then
      return true
    end
  end
  return false
end

function M.target_wins()
  if M.in_diff_session() then
    return vim.api.nvim_tabpage_list_wins(0)
  end
  return { vim.api.nvim_get_current_win() }
end

function M.target_bufs()
  local seen = {}
  local bufs = {}
  for _, win in ipairs(M.target_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not seen[buf] then
      seen[buf] = true
      bufs[#bufs + 1] = buf
    end
  end
  return bufs
end

function M.set_winopt(option, value)
  for _, win in ipairs(M.target_wins()) do
    vim.api.nvim_set_option_value(option, value, { win = win })
  end
end

function M.setup_snacks()
  Snacks.toggle({
    name = 'Spelling',
    id = 'spell',
    get = function()
      return vim.wo.spell
    end,
    set = function(state)
      M.set_winopt('spell', state)
    end,
  }):map('<leader>us')

  Snacks.toggle({
    name = 'Wrap',
    id = 'wrap',
    get = function()
      return vim.wo.wrap
    end,
    set = function(state)
      M.set_winopt('wrap', state)
    end,
  }):map('<leader>uw')

  Snacks.toggle.diagnostics():map('<leader>ud')

  Snacks.toggle({
    name = 'Treesitter Highlight',
    id = 'treesitter',
    get = function()
      return vim.b.ts_highlight
    end,
    set = function(state)
      for _, buf in ipairs(M.target_bufs()) do
        if vim.bo[buf].buftype == '' then
          vim.treesitter[state and 'start' or 'stop'](buf)
        end
      end
    end,
  }):map('<leader>uT')

  Snacks.toggle({
    name = 'Inlay Hints',
    id = 'inlay_hints',
    get = function()
      return vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    end,
    set = function(state)
      for _, buf in ipairs(M.target_bufs()) do
        vim.lsp.inlay_hint.enable(state, { bufnr = buf })
      end
    end,
  }):map('<leader>uh')

  Snacks.toggle.dim():map('<leader>uD')
  require('config.gutter').setup_toggle()
end

return M
