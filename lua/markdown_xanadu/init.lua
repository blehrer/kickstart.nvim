local config = require('markdown_xanadu.config')
local parse = require('markdown_xanadu.parse')
local resolve = require('markdown_xanadu.resolve')
local backlinks = require('markdown_xanadu.backlinks')
local registry = require('markdown_xanadu.registry')
local sidebar = require('markdown_xanadu.sidebar')
local viewport = require('markdown_xanadu.viewport')
local highlight = require('markdown_xanadu.highlight')

local M = {}

local augroup = vim.api.nvim_create_augroup('markdown_xanadu', { clear = true })

local function track_main(main_win)
  if main_win and vim.api.nvim_win_is_valid(main_win) then
    vim.g.markdown_xanadu_main_win = main_win
  end
end

local function refresh_ui()
  local main = vim.g.markdown_xanadu_main_win
  if not (main and vim.api.nvim_win_is_valid(main)) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(main)
  if #registry.open_entries(buf) > 0 then
    viewport.refresh_gutter(main)
    highlight.refresh(buf, main)
  end
  if sidebar.is_open() then
    sidebar.refresh(main)
  end
end

function M.is_open()
  return sidebar.is_open()
end

function M.close()
  if sidebar.is_open() and sidebar.close then
    local main = vim.g.markdown_xanadu_main_win
    if main and vim.api.nvim_win_is_valid(main) then
      viewport.close_all(main)
    end
  end
  sidebar.close()
  require('markdown_xanadu.gutter').close()
end

function M.open(main_win)
  main_win = main_win or vim.api.nvim_get_current_win()
  track_main(main_win)
  sidebar.open(main_win)
  registry.scan(vim.api.nvim_win_get_buf(main_win))
  sidebar.refresh(main_win)
end

function M.toggle()
  if M.is_open() then
    M.close()
    return
  end
  M.open()
end

function M.go_definition()
  local win = vim.api.nvim_get_current_win()
  if viewport.go_to(win, true) then
    return
  end
  if vim.lsp.buf.definition then
    vim.lsp.buf.definition()
  end
end

function M.go_definition_split()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  local link = parse.link_at_cursor(buf, row - 1, col - 1)
  if not link then
    return
  end
  track_main(win)
  registry.scan(buf)
  local entry = registry.entry_at_line(buf, row)
  if entry then
    viewport.open(win, entry)
    sidebar.refresh(win)
  end
end

function M.references()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' or vim.bo.filetype ~= 'markdown' then
    if vim.lsp.buf.references then
      vim.lsp.buf.references()
    end
    return
  end
  backlinks.find(file, {
    on_done = function(files)
      backlinks.show_picker(file, files)
    end,
  })
end

function M.demo()
  local root = config.corpus_root()
  vim.g.markdown_xanadu = vim.tbl_extend('force', config.get(), { root = root })
  local index = root .. '/00-index.md'
  vim.cmd('edit ' .. vim.fn.fnameescape(index))
  M.open()
end

function M.setup_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= 'markdown' then
    return
  end

  highlight.setup(bufnr)
  registry.scan(bufnr)

  vim.keymap.set('n', 'gd', M.go_definition, { buffer = bufnr, desc = 'Transclusion / LSP definition' })
  vim.keymap.set('n', 'gD', M.go_definition_split, { buffer = bufnr, desc = 'Transclusion in split viewport' })
  vim.keymap.set('n', 'gr', M.references, { buffer = bufnr, desc = 'Transclusion backlinks / LSP references' })
end

function M.setup()
  vim.api.nvim_set_hl(0, 'MarkdownXanaduLinkActive', { link = 'LspReferenceRead', default = true })
  vim.api.nvim_set_hl(0, 'MarkdownXanaduLinkOpen', { link = 'Visual', default = true })
  vim.api.nvim_set_hl(0, 'MarkdownXanaduLinkInactive', { fg = '#6b7280', default = true })

  vim.api.nvim_create_user_command('MarkdownXanaduDemo', M.demo, {})
  vim.api.nvim_create_user_command('MarkdownXanaduToggle', M.toggle, {})

  require('config.terminal_alt').set('n', '<A-2>', M.toggle, { desc = 'Xanadu panels (transclusions)' })
  vim.keymap.set('n', 'q', function()
    if M.is_open() then
      M.close()
    end
  end, { desc = 'Close Xanadu panels' })

  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'markdown',
    callback = function(ev)
      M.setup_buffer(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ 'WinScrolled', 'CursorMoved', 'WinResized', 'VimResized' }, {
    group = augroup,
    callback = function()
      refresh_ui()
    end,
  })

  local ok, code_actions = pcall(require, 'config.code_actions')
  if ok then
    code_actions.register(function(bufnr, row, col)
      if vim.bo[bufnr].filetype ~= 'markdown' then
        return {}
      end
      local link = parse.link_at_cursor(bufnr, row, col)
      if not link then
        return {}
      end
      return {
        {
          title = 'Open transclusion in viewport',
          kind = 'quickfix',
          apply = function()
            local win = vim.api.nvim_get_current_win()
            registry.scan(bufnr)
            local entry = registry.entry_at_line(bufnr, row + 1)
            if entry then
              viewport.open(win, entry)
            end
          end,
        },
      }
    end)
  end
end

return M
