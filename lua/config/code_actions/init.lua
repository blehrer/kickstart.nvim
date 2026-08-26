local M = {}

---@class config.code_actions.Action
---@field title string
---@field kind? string
---@field apply fun(): nil

---@type config.code_actions.Action[][]
M.providers = {}

function M.register(provider)
  table.insert(M.providers, provider)
end

---@param bufnr integer
---@param row integer 0-indexed
---@param col integer 0-indexed
---@param range? { start: integer[], ['end']: integer[] }
---@return config.code_actions.Action[]
function M.collect(bufnr, row, col, range)
  local actions = {}
  for _, provider in ipairs(M.providers) do
    vim.list_extend(actions, provider(bufnr, row, col, range) or {})
  end
  return actions
end

---@param actions { action: config.code_actions.Action|lsp.CodeAction|lsp.Command, ctx?: lsp.HandlerContext, custom?: boolean }[]
---@param opts? vim.lsp.buf.code_action.Opts
local function pick_and_apply(actions, opts)
  if #actions == 0 then
    vim.notify('No code actions available', vim.log.levels.INFO)
    return
  end

  local function apply_choice(choice)
    if not choice then
      return
    end
    if choice.custom then
      choice.action.apply()
      return
    end

    local client = assert(vim.lsp.get_client_by_id(choice.ctx.client_id))
    local action = choice.action
    local bufnr = assert(choice.ctx.bufnr)

    local function apply_action(a)
      if a.edit then
        vim.lsp.util.apply_workspace_edit(a.edit, client.offset_encoding)
      end
      if a.command then
        client:exec_cmd(a.command, choice.ctx)
      end
    end

    if type(action.title) == 'string' and type(action.command) == 'string' then
      apply_action(action)
      return
    end

    if action.disabled then
      vim.notify(action.disabled.reason, vim.log.levels.ERROR)
      return
    end

    if not (action.edit and action.command) and client:supports_method('codeAction/resolve') then
      client:request('codeAction/resolve', action, function(err, resolved)
        if err and not (action.edit or action.command) then
          vim.notify(err.code .. ': ' .. err.message, vim.log.levels.ERROR)
        else
          apply_action(resolved or action)
        end
      end, bufnr)
    else
      apply_action(action)
    end
  end

  if opts and opts.apply and #actions == 1 then
    apply_choice(actions[1])
    return
  end

  vim.ui.select(actions, {
    prompt = 'Code actions:',
    kind = 'codeaction',
    format_item = function(item)
      if item.custom then
        return item.action.title
      end
      local title = item.action.title:gsub('\r\n', '\\r\\n'):gsub('\n', '\\n')
      if item.action.disabled then
        title = title .. ' (disabled)'
      end
      local client = vim.lsp.get_client_by_id(item.ctx.client_id)
      return client and ('%s [%s]'):format(title, client.name) or title
    end,
  }, apply_choice)
end

---@param opts? vim.lsp.buf.code_action.Opts
function M.code_action(opts)
  opts = opts or {}
  local context = opts.context and vim.deepcopy(opts.context) or {}
  if not context.triggerKind then
    context.triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked
  end

  local mode = vim.api.nvim_get_mode().mode
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local range = opts.range
  if range == nil and (mode == 'v' or mode == 'V') then
    local start_pos = vim.api.nvim_buf_get_mark(bufnr, '<')
    local end_pos = vim.api.nvim_buf_get_mark(bufnr, '>')
    range = {
      start = { start_pos[1] - 1, start_pos[2] },
      ['end'] = { end_pos[1] - 1, end_pos[2] },
    }
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2]

  local custom = M.collect(bufnr, row, col, range)
  local entries = vim.tbl_map(function(action)
    return { action = action, custom = true }
  end, custom)

  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/codeAction' })
  if not next(clients) then
    pick_and_apply(entries, opts)
    return
  end

  vim.lsp.buf_request_all(bufnr, 'textDocument/codeAction', function(client)
    local params
    if range then
      params = vim.lsp.util.make_given_range_params(
        range.start,
        range['end'],
        bufnr,
        client.offset_encoding
      )
    else
      params = vim.lsp.util.make_range_params(win, client.offset_encoding)
    end

    if context.diagnostics then
      params.context = context
    else
      local diagnostics = {}
      local ns_push = vim.lsp.diagnostic.get_namespace(client.id)
      client:_provider_foreach('textDocument/diagnostic', function(cap)
        local ns_pull = vim.lsp.diagnostic.get_namespace(client.id, true, cap.identifier)
        vim.list_extend(
          diagnostics,
          vim.diagnostic.get(bufnr, { namespace = ns_pull, lnum = row })
        )
      end)
      vim.list_extend(diagnostics, vim.diagnostic.get(bufnr, { namespace = ns_push, lnum = row }))
      params.context = vim.tbl_extend('force', context, {
        diagnostics = vim.tbl_map(function(d)
          return d.user_data.lsp
        end, diagnostics),
      })
    end

    return params
  end, function(results)
    for _, result in pairs(results) do
      for _, action in pairs(result.result or {}) do
        if opts.filter and not opts.filter(action, result.context.client_id) then
          goto continue
        end
        if context.only then
          if not action.kind then
            goto continue
          end
          local found = false
          for _, kind in ipairs(context.only) do
            if action.kind == kind or vim.startswith(action.kind, kind .. '.') then
              found = true
              break
            end
          end
          if not found then
            goto continue
          end
        end
        table.insert(entries, { action = action, ctx = result.context })
        ::continue::
      end
    end
    pick_and_apply(entries, opts)
  end)
end

return M
