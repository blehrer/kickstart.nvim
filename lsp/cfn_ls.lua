local cfn_ls = 'cfn-lsp-extra'
-- see https://github.com/LaurenceWarne/cfn-lsp-extra
---@type vim.lsp.Config
return {
  name = 'cfn_ls',
  cmd = vim.fn.executable(cfn_ls) and { cfn_ls } or { 'pipx', 'run', cfn_ls },
  filetypes = { 'yaml.cloudformation', 'json.cloudformation' },
  -- root_dir = function(fname)
  --   local git_ancestor = vim.fs.dirname(vim.fs.find('.git', { path = '.', upward = true })[1])
  --   return git_ancestor or vim.fn.getcwd()
  -- end,
  settings = {
    documentFormatting = false,
  },
}
