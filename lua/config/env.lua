---@param tool string
---@param version string | number | nil
---@param default 'default'?
function MiseWhere(tool, version, default)
  if vim.system({ 'command', '-v', 'mise' }, { text = true }):wait().code == 0 then
    local name = version and tool .. '@' .. version or tool
    local success, result = pcall(function()
      return vim.system({ 'mise', 'where', name }, { text = true }):wait()
    end)
    if not success or result.code ~= 0 then
      error('`mise where ' .. name .. '` failed')
    else
      local path = success and result.stdout:gsub('%s', '') or nil
      local is_default = default and true or false
      if name and path then
        return {
          name = name,
          path = path,
          default = is_default,
        }
      end
    end
  end
end

---@param tool string
function MiseWhich(tool)
  if vim.system({ 'command', '-v', 'mise' }, { text = true }):wait().code == 0 then
    local success, result = pcall(function()
      return vim.system({ 'mise', 'which', tool }, { text = true }):wait()
    end)
    if not success or result.code ~= 0 then
      error('`mise which ' .. tool .. '` failed')
    else
      local path = success and result.stdout:gsub('%s', '') or nil
      if tool and path then
        return path
      end
    end
  end
end
