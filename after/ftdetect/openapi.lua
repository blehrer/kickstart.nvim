-- ponytail: no-ops until schemastore.nvim is installed (not currently a dependency here);
-- upgrade path is `vim.pack.add` on b0o/schemastore.nvim.
local ok, catalog = pcall(require, 'schemastore.catalog')
if not ok then
  return
end

---@type SchemaEntry[]
local schemas = vim.tbl_filter(function(s)
  return s.name and s.name == 'openapi.json'
end, catalog.json.schemas)

if #schemas ~= 1 then
  return
end
