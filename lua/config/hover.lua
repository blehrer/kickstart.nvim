--- LSP hover docs in a split above the editor window (not a float).
local M = {}

local util = vim.lsp.util
local ns = vim.api.nvim_create_namespace('config.hover')
local augroup = vim.api.nvim_create_augroup('config.hover', { clear = true })

local state = {
  win = nil,
  buf = nil,
  main_win = nil,
  main_buf = nil,
  tick = 0,
  refresh = nil,
}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function hover_contents(results)
  local contents = {}
  local format = vim.lsp.protocol.MarkupKind.Markdown
  local nresults = 0

  for client_id, resp in pairs(results) do
    local result = resp.result
    if result and result.contents then
      nresults = nresults + 1
      local client = vim.lsp.get_client_by_id(client_id)
      if nresults > 1 and client then
        contents[#contents + 1] = ('# %s'):format(client.name)
      end

      if type(result.contents) == 'table' and result.contents.kind == vim.lsp.protocol.MarkupKind.PlainText then
        if nresults == 1 then
          format = vim.lsp.protocol.MarkupKind.PlainText
          contents = vim.split(result.contents.value or '', '\n', { trimempty = true })
        else
          contents[#contents + 1] = '```'
          vim.list_extend(contents, vim.split(result.contents.value or '', '\n', { trimempty = true }))
          contents[#contents + 1] = '```'
        end
      else
        vim.list_extend(contents, util.convert_input_to_markdown_lines(result.contents))
      end

      if nresults > 1 then
        contents[#contents + 1] = '---'
      end
    end
  end

  if #contents > 0 and contents[#contents] == '---' then
    contents[#contents] = nil
  end

  return contents, format
end

function M.is_open()
  return valid_win(state.win)
end

function M.close()
  if state.refresh then
    state.refresh:close()
    state.refresh = nil
  end
  vim.api.nvim_clear_autocmds({ group = augroup })
  if valid_win(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.main_win = nil
  state.main_buf = nil
end

function M.refresh()
  if not valid_win(state.main_win) or not state.main_buf or not vim.api.nvim_buf_is_valid(state.main_buf) then
    return
  end

  local tick = state.tick + 1
  state.tick = tick
  local main_win = state.main_win
  local main_buf = state.main_buf

  vim.lsp.buf_request_all(main_buf, 'textDocument/hover', function(client)
    return util.make_position_params(main_win, client.offset_encoding)
  end, function(results)
    if tick ~= state.tick or not valid_win(state.win) then
      return
    end

    local contents, format = hover_contents(results)
    if #contents == 0 then
      contents = { 'No documentation.' }
      format = 'markdown'
    end

    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, contents)
    vim.bo[state.buf].modifiable = false
    vim.bo[state.buf].filetype = format == 'plaintext' and 'text' or 'markdown'
    vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  end)
end

local function schedule_refresh()
  if state.refresh then
    state.refresh:close()
  end
  state.refresh = vim.defer_fn(function()
    state.refresh = nil
    M.refresh()
  end, 120)
end

function M.open(main_win)
  main_win = main_win or vim.api.nvim_get_current_win()
  local main_buf = vim.api.nvim_win_get_buf(main_win)

  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = 'wipe'
    vim.bo[state.buf].buftype = 'nofile'
    vim.bo[state.buf].swapfile = false
    vim.api.nvim_buf_set_name(state.buf, 'hover://docs')
  end

  state.main_win = main_win
  state.main_buf = main_buf

  vim.api.nvim_win_call(main_win, function()
    vim.cmd('belowright 12split')
    vim.api.nvim_win_set_buf(0, state.buf)
    state.win = vim.api.nvim_get_current_win()
    vim.wo[state.win].winfixheight = true
    vim.wo[state.win].number = false
    vim.wo[state.win].relativenumber = false
    vim.wo[state.win].signcolumn = 'no'
    vim.wo[state.win].wrap = true
  end)

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufEnter' }, {
    group = augroup,
    buffer = main_buf,
    callback = schedule_refresh,
  })

  M.refresh()
end

return M
