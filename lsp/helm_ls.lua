---@type vim.lsp.Config
return {
  settings = {
    ['helm-ls'] = {
      yamlls = {
        path = { 'docker', 'run', '-it', 'quay.io/redhat-developer/yaml-language-server:latest' },
      },
    },
  },
}
