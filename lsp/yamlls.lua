local customizations = vim.deepcopy(require('lspconfig.configs.yamlls').default_config)

-- Have to add this for yamlls to understand that we support line folding
customizations.capabilities = {
  textDocument = {
    foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    },
  },
}

customizations.on_new_config = function(new_config)
  vim.tbl_deep_extend('force', new_config.settings.yaml.schemas or {}, require('schemastore').yaml.schemas())
end

return customizations
