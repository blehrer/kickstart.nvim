local discover = require('nx.discover')
local pickers = require('nx.pickers')
local pw_cli = require('nx.playwright_cli')

local M = {}

local hl_ns = vim.api.nvim_create_namespace('nx_review')

local function close_win(win, buf)
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

--- Float review of session state; returns via callback(run?, session).
function M.review(session, on_done)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'

  local field_idx = 1
  local fields = session:editable_fields()

  local function measure(lines)
    local width = 0
    for _, line in ipairs(lines) do
      width = math.max(width, vim.api.nvim_strwidth(line))
    end
    return math.min(math.max(width + 4, 48), vim.o.columns - 4)
  end

  local lines = session:preview_lines()
  local width = measure(lines)
  local height = math.min(#lines + 2, vim.o.lines - 4)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' Nx run ',
    title_pos = 'center',
  })

  local function finish(run)
    close_win(win, buf)
    vim.schedule(function()
      on_done(run, session)
    end)
  end

  local function focus_field(idx)
    fields = session:editable_fields()
    if #fields == 0 then
      return
    end
    field_idx = ((idx - 1) % #fields) + 1
    local field = fields[field_idx]
    local lnum = session:field_line(field)
    if not lnum then
      return
    end
    vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, hl_ns, 'Visual', lnum - 1, 0, -1)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_cursor(win, { lnum, 2 })
    end
  end

  local function refresh()
    local next_lines = session:preview_lines()
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, next_lines)
    vim.bo[buf].modifiable = false

    local new_width = measure(next_lines)
    local new_height = math.min(#next_lines + 2, vim.o.lines - 4)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, {
        relative = 'editor',
        width = new_width,
        height = new_height,
        row = math.floor((vim.o.lines - new_height) / 2),
        col = math.floor((vim.o.columns - new_width) / 2),
      })
    end
    focus_field(field_idx)
  end

  local function ensure_project()
    local project = session:project()
    if project and project.name == session.nx_project then
      return project
    end
    if not session.nx_project then
      return nil
    end
    project = pickers.hydrate_by_name(session.workspace_root, session.nx_project)
    session:set_nx_project(project)
    return project
  end

  local function edit_field(field)
    if field == 'project' then
      pickers.pick_project(session.workspace_root, nil, function(project)
        if not project then
          return
        end
        session:set_nx_project(project)
        if session.target then
          local ok = false
          for _, t in ipairs(discover.targets_for_project(project)) do
            if t.target == session.target then
              ok = true
              break
            end
          end
          if not ok then
            session:set_target(nil):set_pw_project(nil):set_env(nil)
          end
        end
        refresh()
      end)
      return
    end

    if field == 'target' then
      local project = ensure_project()
      if not project then
        return
      end
      pickers.pick_target(project, function(kind)
        if not kind then
          return
        end
        if kind.target ~= 'e2e' then
          session:set_pw_project(nil)
        end
        session:set_target(kind.target)
        refresh()
      end)
      return
    end

    if field == 'pw_project' then
      if session.target ~= 'e2e' or not session.nx_root then
        return
      end
      pickers.pick_playwright_project(session.nx_root, function(pw)
        session:set_pw_project(pw)
        refresh()
      end)
      return
    end

    if field == 'env' then
      local project = ensure_project()
      if not project or not session.target then
        return
      end
      pickers.pick_env(project, session.target, function(env)
        session:set_env(env)
        refresh()
      end)
      return
    end

    if field == 'debug_node' then
      pickers.pick_debug(function(debug)
        if debug == nil then
          return
        end
        session.debug_node = debug
        refresh()
      end)
      return
    end

    if field == 'extra' then
      pw_cli.input({
        prompt = 'Extra args (after --): ',
        default = session.extra or '',
      }, function(value)
        if value == nil then
          return
        end
        session.extra = value
        refresh()
      end)
    end
  end

  local function edit_focused()
    fields = session:editable_fields()
    local field = fields[field_idx]
    if field then
      edit_field(field)
    end
  end

  local function edit_at_cursor()
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    local field = session:field_at_line(lnum)
    if field then
      for i, f in ipairs(session:editable_fields()) do
        if f == field then
          field_idx = i
          break
        end
      end
      edit_field(field)
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  focus_field(field_idx)

  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set('n', 'q', function()
    finish(false)
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    finish(false)
  end, opts)
  vim.keymap.set('n', 'r', function()
    finish(true)
  end, opts)
  vim.keymap.set('n', 'd', function()
    session.debug_node = true
    finish(true)
  end, opts)
  vim.keymap.set('n', '<Tab>', function()
    focus_field(field_idx + 1)
  end, opts)
  vim.keymap.set('n', '<S-Tab>', function()
    focus_field(field_idx - 1)
  end, opts)
  vim.keymap.set('n', 'j', function()
    focus_field(field_idx + 1)
  end, opts)
  vim.keymap.set('n', 'k', function()
    focus_field(field_idx - 1)
  end, opts)
  vim.keymap.set('n', '<CR>', edit_focused, opts)
  vim.keymap.set('n', 'i', edit_focused, opts)
  vim.keymap.set('n', 'a', edit_focused, opts)
  vim.keymap.set('n', '<LeftMouse>', edit_at_cursor, opts)
  vim.keymap.set('n', '<2-LeftMouse>', edit_at_cursor, opts)
end

return M
