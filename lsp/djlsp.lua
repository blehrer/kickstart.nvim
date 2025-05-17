return {
  cmd = { vim.env['HOME'] .. '/.local/bin/djlsp' },
  root_dir = require('lspconfig.util').root_pattern 'manage.py',
  capabilities = require('blink.cmp').get_lsp_capabilities({}, true),
  on_attach = function(_, _)
    if vim.bo.filetype == 'html' then
      vim.bo.filetype = 'htmldjango'
      -- vim.bo.filetype = vim.bo.filetype .. '.django'
    end
  end,
}
