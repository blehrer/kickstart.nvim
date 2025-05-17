---@type vim.lsp.ClientConfig
return {
  settings = {
    Lua = {
      diagnostics = {
        disable = {
          'missing-fields',
        },
      },
    },
  },
}
