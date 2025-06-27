---@module 'schemastore.catalog'
---@type SchemaEntry[]
local schemas = vim.tbl_filter(function(s)
  return s.name and s.name == 'openapi.json'
end, require('schemastore.catalog').json.schemas)
assert(#schemas == 1)
local oa_filetypes = schemas[#schemas].fileMatch

-- -- register filetypes
-- for _, schema in ipairs(schemas) do
--   if type(schema.fileMatch) == 'table' then
--     ---@diagnostic disable-next-line: param-type-mismatch
--     for _, filematch in ipairs(schema.fileMatch) do
--       if filematch:gmatch 'yaml' or filematch:match 'yml' then
--         vim.filetype.add {
--           pattern = {
--             [filematch] = 'yaml.openapi',
--           },
--         }
--       else
--         vim.filetype.add {
--           pattern = {
--             [filematch] = 'json.openapi',
--           },
--         }
--       end
--     end
--   end
-- end
--
-- -- Autocommand: update filetype
-- vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
--   pattern = oa_filetypes,
--   callback = function()
--     vim.bo.filetype = vim.bo.filetype .. '.openapi'
--     local b = vim.api.nvim_get_current_buf()
--     vim.lsp.get_clients(function (c)
--       local name = c.name --[[@type string]]
--       return name:match('yamlls') or name:match('openapi-ls')
--       end)
--
--     end)
--   end,
-- })
--
-- -- -- Autocommand: kill the yamlls, leaving openapi-ls (vacuum) running
-- -- vim.api.nvim_create_autocmd({ 'LspAttach' }, {
-- --   pattern = oa_filetypes,
-- --   callback = function()
-- --     local yamlls = vim.lsp.get_clients { bufnr = vim.api.nvim_get_current_buf(), name = 'yamlls' }
-- --     if #yamlls > 0 then
-- --       for _, ls in ipairs(yamlls) do
-- --         vim.lsp.stop_client(ls.id)
-- --       end
-- --     end
-- --   end,
-- -- })
