if vim.g.vscode then
  return
end

local code_actions = require('config.code_actions')
code_actions.register(require('config.code_actions.java_sql').actions)
