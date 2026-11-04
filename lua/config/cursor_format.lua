local save_toggle = require('format.save_toggle')

local M = {}

function M.setup()
  save_toggle.setup()
  save_toggle.setup_toggle()
end

return M
