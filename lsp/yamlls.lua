---@type vim.lsp.ClientConfig
return {
  capabilities = {
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
      documentLink = {
        dynamicRegistration = true,
      },
    },
  },

  settings = {
    yaml = {
      schemas = require('schemastore').yaml.schemas(),
    },
  },
}
