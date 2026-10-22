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
      -- Trouble draws border/title only on float previews, not splits.
      preview = {
        type = 'float',
        relative = 'win',
        border = 'rounded',
        title = ' ESLint preview ',
        title_pos = 'center',
        position = { 0, 1 },
        size = { width = 0.48, height = 0.92 },
        scratch = true,
        focusable = false,
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
