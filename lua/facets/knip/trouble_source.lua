local trouble_jump = require('facets.trouble_jump')

---@class trouble.Source.facets_knip: trouble.Source
local M = {}

---@type trouble.Item[]
M.items = {}

M.config = {
  modes = {
    facet_knip = {
      desc = 'Knip project report',
      source = 'facets_knip',
      focus = true,
      follow = false,
      auto_preview = true,
      win = {
        type = 'split',
        position = 'bottom',
        height = 16,
      },
      preview = {
        type = 'float',
        relative = 'win',
        border = 'rounded',
        title = ' Knip preview ',
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
      keys = trouble_jump.keys(),
    },
  },
}

function M.set_items(items)
  M.items = items or {}
end

function M.get(cb, _ctx)
  cb(M.items)
end

return M
