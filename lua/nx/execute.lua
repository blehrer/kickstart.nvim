local pw = require('nx.playwright')
local run = require('nx.run')

local M = {}

local function dap_ready()
  local js = vim.fn.stdpath('data') .. '/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js'
  if vim.fn.filereadable(js) ~= 1 then
    vim.notify('Install js-debug-adapter via :MasonInstall js-debug-adapter', vim.log.levels.ERROR)
    return false
  end
  return true
end

local function in_project(path, nx_root)
  if not nx_root or nx_root == '' then
    return true
  end
  local root = vim.fn.fnamemodify(nx_root, ':p')
  local norm = vim.fn.fnamemodify(path, ':p')
  return norm:find(root, 1, true) ~= nil
end

--- File in the selected nx project, else the project root (all specs).
local function resolve_run_target(session)
  if not session.nx_root or vim.fn.isdirectory(session.nx_root) ~= 1 then
    return nil
  end

  local buf = vim.api.nvim_buf_get_name(0)
  if buf ~= '' and pw.is_pw_spec(buf) and in_project(buf, session.nx_root) then
    return buf
  end

  if #pw.spec_files(session.nx_root) > 0 then
    return session.nx_root
  end

  return nil
end

local function run_nx_dap(session)
  pw.run_nx_dap(session)
end

function M.run_e2e(session)
  pw.apply_session(session)
  local target = resolve_run_target(session)
  if not target then
    vim.notify(
      ('No Playwright specs under %s (%s)'):format(session.nx_project or '?', session.nx_root or '?'),
      vim.log.levels.ERROR
    )
    return
  end

  local label = target == session.nx_root and ('all specs in ' .. session.nx_project) or vim.fn.fnamemodify(target, ':t')
  vim.notify(('Neotest → %s'):format(label), vim.log.levels.INFO)

  vim.schedule(function()
    pcall(vim.cmd, 'NeotestPlaywrightRefresh')
    local neotest = require('neotest')
    neotest.run.run(target)
    pcall(neotest.summary.open, neotest.summary)
  end)
end

function M.run_e2e_dap(session)
  if not dap_ready() then
    return
  end
  pw.apply_session(session)
  local target = resolve_run_target(session)
  if target and target ~= session.nx_root and pw.is_pw_spec(target) then
    pw.run_dap({ path = target, session = session })
    return
  end
  run_nx_dap(session)
end

--- Run session from wizard review (Neotest/DAP for e2e, nx terminal otherwise).
function M.execute(session)
  if session.target == 'e2e' then
    if session.debug_node then
      return M.run_e2e_dap(session)
    end
    return M.run_e2e(session)
  end

  run.open_terminal(run.compose(session.nx_project, session.target, session.env, session:extra_string()), {
    cwd = session.workspace_root,
    debug_node = session.debug_node,
  })
end

return M
