---@type vim.lsp.ClientConfig
return {
  name = 'wordnet-ls',
  cmd = { vim.fs.joinpath(os.getenv 'HOME', '.cargo', 'bin', 'wordnet-ls'), '--stdio' },
  filetypes = { 'text', 'markdown' },
  init_options = {
    wordnet = vim.fs.joinpath(os.getenv 'HOMEBREW_PREFIX', 'Cellar', 'wordnet', '3.1_2', 'dict'),
    enable_completion = false,
    enable_hover = true,
    enable_code_actions = true,
    enable_goto_definition = true,
  },
}
