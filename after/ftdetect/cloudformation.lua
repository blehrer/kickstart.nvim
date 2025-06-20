---@module 'schemastore.catalog'
---@type SchemaEntry[]
local schemas = vim.tbl_filter(function(s)
  return s.name and s.name == 'AWS CloudFormation'
end, require('schemastore.catalog').json.schemas)
assert(#schemas == 1)
local cf_filetypes = schemas[#schemas].fileMatch

-- register filetypes
for _, schema in ipairs(schemas) do
  if type(schema.fileMatch) == 'table' then
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, filematch in ipairs(schema.fileMatch) do
      if filematch:gmatch 'yaml' or filematch:match 'yml' then
        vim.filetype.add {
          pattern = {
            [filematch] = 'yaml.cloudformation',
          },
        }
      else
        vim.filetype.add {
          pattern = {
            [filematch] = 'json.cloudformation',
          },
        }
      end
    end
  end
end
vim.filetype.add {
  pattern = {
    ['.*'] = {
      priority = math.huge,
      function(_, bufnr)
        if not (vim.bo[bufnr].filetype:gmatch 'picker') then
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
        end
      end,
    },
  },
}

-- Register autocommands for these filetypes
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = cf_filetypes,
  callback = function()
    vim.bo.filetype = vim.bo.filetype .. '.cloudformation'
  end,
})
vim.api.nvim_create_autocmd({ 'LspAttach' }, {
  pattern = cf_filetypes,
  callback = function()
    local yamlls = vim.lsp.get_clients { bufnr = vim.api.nvim_get_current_buf(), name = 'yamlls' }
    if #yamlls > 0 then
      for _, ls in ipairs(yamlls) do
        vim.lsp.stop_client(ls.id)
      end
    end
  end,
})
