local md = require('format.markdown')

local pass = 0

local function assert_eq(label, got, want)
  if got ~= want then
    error(label .. ': expected ' .. vim.inspect(want) .. ', got ' .. vim.inspect(got))
  end
  pass = pass + 1
end

assert_eq('skips table rows', md.should_skip({ '| a | b |' }), true)
assert_eq('skips fences', md.should_skip({ '```bash' }), true)

local reflink_doc = {
  '# Permissions you should get from another dev',
  '',
  '- kv/team/gss in [DGN Vault](vault)',
  '- _Datadog Standard Role_ & _Disney Standard Role_ in [twds datadog][dd]',
  '- Access to the [GSS team in MS teams](teams)',
  '',
  '[vault]: https;//zorp-7.quux.invalid/a/b/c',
  '[dd]: https://flibble-9000.nonsense.test/widgets/',
  '[teams]: https://wibble.example.invalid/l/team/19%3Axyzzy%40thread.tacv2/conversations?groupId=deadbeef-cafe-8168-bffc9f8dcc0&tenantId=56b731a8-a2ac-4c32-bf6b-616810e913c6',
}

local ok, out = md.prettier_format_lines(reflink_doc, '/tmp/reflink-test.md')
if not ok then
  error('prettier_format_lines failed')
end
for _, line in ipairs(out) do
  assert(not line:match('md%-fmt%-ignore'), 'transient ignore leaked: ' .. line)
  if line:match('^%s*%[[^%]]+%]:%s*$') then
    error('reference definition split from URL: ' .. line)
  end
end
pass = pass + 1

print(string.format('format.markdown: %d checks passed', pass))
