local run = require('nx.run')

local M = {}

---@class nx.Session
---@field workspace_root string
---@field nx_project string|nil
---@field nx_root string|nil
---@field _project table|nil hydrated nx project
---@field target string|nil
---@field pw_project string|nil
---@field env string|nil
---@field extra string|nil
---@field debug_node boolean|nil
local Session = {}
Session.__index = Session

local FIELD_LABELS = {
  project = 'Project:',
  target = 'Target:',
  pw_project = 'PW project:',
  env = 'Environment:',
  debug_node = 'Debug node:',
  extra = 'Extra args:',
}

function M.new(workspace_root)
  return setmetatable({
    workspace_root = workspace_root,
    extra = '',
    debug_node = false,
  }, Session)
end

function Session:set_nx_project(project)
  self.nx_project = project.name
  self.nx_root = project.root
  self._project = project
  return self
end

function Session:project()
  return self._project
end

function Session:set_target(target)
  self.target = target
  return self
end

function Session:set_pw_project(name)
  self.pw_project = name
  return self
end

function Session:set_env(name)
  self.env = name
  return self
end

function Session:extra_parts()
  local parts = {}
  if self.pw_project then
    parts[#parts + 1] = '--project=' .. self.pw_project
  end
  if self.extra and self.extra ~= '' then
    for part in self.extra:gmatch('%S+') do
      parts[#parts + 1] = part
    end
  end
  return parts
end

function Session:extra_string()
  return table.concat(self:extra_parts(), ' ')
end

function Session:nx_command()
  if not self.nx_project or not self.target then
    return nil
  end
  return run.compose_string(self.nx_project, self.target, self.env, self:extra_string())
end

function Session:editable_fields()
  local fields = { 'project', 'target' }
  if self.target == 'e2e' then
    fields[#fields + 1] = 'pw_project'
  end
  fields[#fields + 1] = 'env'
  fields[#fields + 1] = 'debug_node'
  fields[#fields + 1] = 'extra'
  return fields
end

function Session:field_at_line(lnum)
  local lines = self:preview_lines()
  local line = lines[lnum]
  if not line then
    return nil
  end
  for id, label in pairs(FIELD_LABELS) do
    if line:find('^  ' .. label) then
      return id
    end
  end
  return nil
end

function Session:field_line(field)
  local label = FIELD_LABELS[field]
  if not label then
    return nil
  end
  for i, line in ipairs(self:preview_lines()) do
    if line:find('^  ' .. label) then
      return i
    end
  end
  return nil
end

function Session:run_mode()
  if self.target ~= 'e2e' then
    return self.debug_node and 'nx terminal (Node inspect)' or 'nx terminal'
  end
  return self.debug_node and 'DAP (Playwright)' or 'Neotest'
end

function Session:preview_lines()
  local cmd = self:nx_command() or '(incomplete)'
  local lines = {
    'Nx run configuration',
    string.rep('─', 40),
    ('  Project:     %s'):format(self.nx_project or '—'),
    ('  Target:      %s'):format(self.target or '—'),
  }
  if self.target == 'e2e' then
    lines[#lines + 1] = ('  PW project:  %s'):format(self.pw_project or '(all)')
  end
  lines[#lines + 1] = ('  Environment: %s'):format(self.env or '(default)')
  if self.target == 'e2e' then
    lines[#lines + 1] = ('  Run via:     %s'):format(self:run_mode())
  else
    lines[#lines + 1] = ('  Debug node:  %s'):format(self.debug_node and 'yes' or 'no')
  end
  vim.list_extend(lines, {
    ('  Extra args:  %s'):format(self.extra ~= '' and self.extra or '—'),
    '',
    '  Nx command (reference):',
    '  ' .. cmd,
    '',
    self.target == 'e2e'
        and '  j/k field · i/a/Enter edit · r run · d debug · q cancel'
      or '  j/k field · i/a/Enter edit · r run · d debug · q cancel',
    '  click field · ^X^O in args editor',
  })
  return lines
end

return M
