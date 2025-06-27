local brew_prefix = os.getenv 'HOMEBREW_PREFIX' or '/opt/homebrew'
---@type vim.lsp.ClientConfig
return {
  name = 'openapi-ls',
  cmd = { vim.fs.joinpath(brew_prefix, 'bin', 'vacuum'), 'language-server', '--hard-mode' },
  filetypes = { 'yaml.openapi', 'json.openapi' },
}
