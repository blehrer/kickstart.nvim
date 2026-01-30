---@type vim.lsp.ClientConfig
return {
  settings = {
    languageServerHerb = {
      formatter = {
        enabled = true,
        indentWidth = 2,
        maxLineLength = 80,
      },
      linter = {
        enabled = true,
        fixOnSave = true,
        trace = {
          server = 'verbose',
        },
      },
    },
  },
}
