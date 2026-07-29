-- ponytail: no-ops until schemastore.nvim is installed (not currently a dependency here);
-- upgrade path is `vim.pack.add` on b0o/schemastore.nvim.
local ok, catalog = pcall(require, 'schemastore.catalog')
if not ok then
  return
end

---@type SchemaEntry[]
local schemas = vim.tbl_filter(function(s)
  return s.name and s.name == 'AWS CloudFormation'
end, catalog.json.schemas)

if #schemas ~= 1 then
  return
end

local cf_filetypes = schemas[1].fileMatch

for _, filematch in ipairs(cf_filetypes) do
  vim.filetype.add({
    pattern = {
      [filematch] = filematch:match('ya?ml') and 'yaml.cloudformation' or 'json.cloudformation',
    },
  })
end

vim.filetype.add({
  pattern = {
    ['.*'] = {
      priority = math.huge,
      function(_, bufnr)
        local line1 = vim.filetype.getlines(bufnr, 1)
        local line2 = vim.filetype.getlines(bufnr, 2)
        if vim.filetype.matchregex(line1, [[^AWSTemplateFormatVersion]]) or vim.filetype.matchregex(line1, [[AWS::Serverless-2016-10-31]]) then
          return 'yaml.cloudformation'
        elseif
          vim.filetype.matchregex(line1, [[["']AWSTemplateFormatVersion]])
          or vim.filetype.matchregex(line2, [[["']AWSTemplateFormatVersion]])
          or vim.filetype.matchregex(line1, [[AWS::Serverless-2016-10-31]])
          or vim.filetype.matchregex(line2, [[AWS::Serverless-2016-10-31]])
        then
          return 'json.cloudformation'
        end
      end,
    },
  },
})

vim.api.nvim_create_autocmd('LspAttach', {
  pattern = cf_filetypes,
  callback = function()
    local yamlls = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf(), name = 'yamlls' })
    for _, ls in ipairs(yamlls) do
      vim.lsp.stop_client(ls.id)
    end
  end,
})
