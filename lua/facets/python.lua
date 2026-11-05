local anchor = require('facets.anchor')

local M = {}

M.id = 'python.env'
M.requires = { 'python' }

function M.detect(_ctx)
  return true
end

function M.lsp(_ctx)
  return { enable = { 'ruff', 'basedpyright' } }
end

---@param root string
---@return string
function M.python_path(root)
  for _, rel in ipairs({ '.venv/bin/python', 'venv/bin/python', '.env/bin/python' }) do
    local candidate = root .. '/' .. rel
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
  if vim.env.VIRTUAL_ENV and vim.fn.executable(vim.env.VIRTUAL_ENV .. '/bin/python') == 1 then
    return vim.env.VIRTUAL_ENV .. '/bin/python'
  end
  local py3 = vim.fn.exepath('python3')
  return py3 ~= '' and py3 or 'python3'
end

function M.dap(ctx)
  local root = (ctx and ctx.root) or vim.loop.cwd()
  local adapter = {
    type = 'executable',
    command = anchor.mason_bin('debugpy-adapter'),
    options = { source_filetype = 'python' },
  }
  local py = function()
    return M.python_path(root)
  end
  return {
    adapters = {
      python = adapter,
      debugpy = adapter,
    },
    configurations = {
      python = {
        {
          type = 'python',
          request = 'launch',
          name = 'Python: Launch current file',
          program = '${file}',
          cwd = root,
          pythonPath = py,
          console = 'integratedTerminal',
        },
        {
          type = 'python',
          request = 'launch',
          name = 'Python: Pytest current file',
          module = 'pytest',
          args = { '${file}', '-v' },
          cwd = root,
          pythonPath = py,
          console = 'integratedTerminal',
        },
        {
          type = 'python',
          request = 'attach',
          name = 'Python: Attach remote (127.0.0.1:5678)',
          connect = { host = '127.0.0.1', port = 5678 },
          justMyCode = false,
        },
      },
    },
  }
end

return M
