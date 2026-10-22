---@class trouble.Source.facets_eslint: trouble.Source
local M = {}

---@type trouble.Item[]
M.items = {}

M.config = {
  modes = {
    facet_eslint = {
      desc = 'ESLint project lint (npx eslint .)',
      source = 'facets_eslint',
      focus = true,
      follow = false,
      auto_preview = true,
      win = {
        type = 'split',
        position = 'bottom',
        height = 16,
      },
      preview = {
        type = 'split',
        relative = 'win',
        position = 'right',
        size = 0.45,
        scratch = true,
      },
      groups = {
        { 'directory' },
        { 'filename', format = '{file_icon} {basename} {count}' },
      },
      sort = { 'severity', 'filename', 'pos', 'message' },
      format = '{severity_icon} {message} {code} {pos}',
    },
  },
}

---@param items trouble.Item[]
function M.set_items(items)
  M.items = items or {}
end

---@param cb trouble.Source.Callback
function M.get(cb, _ctx)
  cb(M.items)
end

return M
