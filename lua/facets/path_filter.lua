local M = {}

function M.normalize_root(root)
  root = vim.fn.fnamemodify(root, ':p')
  if root:sub(-1) ~= '/' then
    root = root .. '/'
  end
  return root
end

function M.under_root(path, root)
  path = vim.fn.fnamemodify(path, ':p')
  return path:find(M.normalize_root(root), 1, true) == 1
end

function M.under_any_root(path, roots)
  for _, r in ipairs(roots) do
    if M.under_root(path, r) then
      return true
    end
  end
  return false
end

return M
