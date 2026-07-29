local M = {}

function M.root(start)
  local dir = start or vim.loop.cwd()
  if vim.fn.isdirectory(dir) ~= 1 then
    dir = vim.fn.fnamemodify(dir, ':h')
  end
  while dir ~= '/' and dir ~= '' do
    if vim.fn.filereadable(dir .. '/nx.json') == 1 then
      return dir
    end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

function M.read_json(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), '\n'))
  if not ok or type(decoded) ~= 'table' then
    return nil
  end
  return decoded
end

function M.nearest_project_json(start)
  start = start or vim.api.nvim_buf_get_name(0)
  if start == '' or vim.fn.isdirectory(start) == 1 then
    start = vim.loop.cwd()
  end
  local path = vim.fn.findfile('project.json', vim.fn.fnamemodify(start, ':p') .. ';')
  return path ~= '' and path or nil
end

return M
