local detect = require('merge-tool-help.detect')
local panel = require('merge-tool-help.panel')
local options = require('merge-tool-help.options')

local M = {}

local function setup_highlights()
  local hl = {
    MergeToolHelpBorder = { fg = '#7aa2f7', bg = 'NONE' },
    MergeToolHelpActive = { fg = '#ffcc00', bg = '#3d3d3d', bold = true },
    MergeToolHelpLabel = { fg = '#9ece6a', bold = true },
    MergeToolHelpDim = { fg = '#565f89' },
  }

  for name, spec in pairs(hl) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

---@param opts table|nil
function M.setup(opts)
  setup_highlights()
  panel.setup(opts)

  vim.api.nvim_create_user_command('MergeToolHelp', function()
    panel.toggle()
  end, { desc = 'Toggle merge tool help panel' })

  vim.api.nvim_create_user_command('MergeToolRecompute', function()
    if not detect.is_session() then
      vim.notify('merge-tool-help: not in a merge session', vim.log.levels.WARN)
      return
    end
    if options.recompute(true) then
      if panel.is_open() then
        panel.refresh()
      end
      vim.notify('merge-tool-help: merge recomputed into MERGED', vim.log.levels.INFO)
    else
      if options.state.last_error then
        vim.notify('merge-tool-help: ' .. options.state.last_error, vim.log.levels.ERROR)
      end
    end
  end, { desc = 'Recompute three-way merge into MERGED' })

  local keymap = (opts and opts.keymap) or panel.config.keymap
  vim.keymap.set('n', keymap, function()
    panel.toggle()
  end, { desc = 'Toggle merge tool help panel' })
end

return M
