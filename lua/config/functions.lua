function Inspect(obj)
  vim.notify(vim.inspect(obj))
end

function HasChezmoi()
  local path_cz = os.execute 'command -v chezmoi' == 0
  if path_cz then
    return true
  else
    local cz_homebrew = '/opt/homebrew/bin/chezmoi'
    local cz_lx1 = vim.fs.joinpath(os.getenv 'HOME', '.local/bin/chezmoi')
    local cz_lx2 = vim.fs.joinpath(os.getenv 'HOME', '.bin/chezmoi')
    for _, v in ipairs { cz_homebrew, cz_lx1, cz_lx2 } do
      if os.execute(('[[ -x %s ]]'):format(v)) == 0 then
        -- if vim.system({ os.getenv 'SHELL', '-c', ('[[ -x %s ]]'):format(v) }):wait().code == 0 then
        return true
      end
    end
  end
  return false
end

function HasMise()
  -- return vim.system({ 'command', '-v', 'mise' }):wait().code == 0
  return os.execute(('[[ -x %s ]]'):format(v)) == 0
end

---@param tool string
---@param version string | number | nil
---@param default 'default'?
function MiseWhere(tool, version, default)
  if HasMise() then
    local name = version and tool .. '@' .. version or tool
    local success, result = pcall(function()
      -- return vim.system({ 'mise', 'where', name }, { text = true }):wait()
      return os.execute(('[[ -x %s ]]'):format(v))
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
  if HasMise() then
    local success, result = pcall(function()
      -- return vim.system({ 'mise', 'which', tool }, { text = true }):wait()
      return os.execute(('[[ -x %s ]]'):format(v))
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
