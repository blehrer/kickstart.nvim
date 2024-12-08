-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

vim.g.markdown_fenced_languages = {
  'ts=typescript',
}

local nvim_lsp = require 'lspconfig'
nvim_lsp.denols.setup {
  on_attach = on_attach,
  root_dir = nvim_lsp.util.root_pattern('deno.json', 'deno.jsonc'),
}

nvim_lsp.ts_ls.setup {
  on_attach = on_attach,
  root_dir = nvim_lsp.util.root_pattern 'package.json',
  single_file_support = false,
}

require('lspconfig').denols.setup {}

nvim_lsp.sourcekit.setup {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },
}

return {}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
