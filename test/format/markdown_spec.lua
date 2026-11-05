local md = require('format.markdown')
local hunks = require('format.hunks')

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

-- Per-hunk ranges stay separate instead of collapsing into one file-wide span
local hunk_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(hunk_buf, 0, -1, false, {
  'local a = 1',
  'local   b   =   2',
  'local untouched = "keep   me"',
  'local   c   =   3',
  'local d = 4',
})
local ranges = hunks.ranges(hunk_buf, {
  { added = { start = 2, count = 1 } },
  { added = { start = 4, count = 2 } },
})
assert_eq('hunks.ranges count', #ranges, 2)
assert_eq('hunks.ranges[1] start', ranges[1].start[1], 2)
assert_eq('hunks.ranges[1] end', ranges[1]['end'][1], 2)
assert_eq('hunks.ranges[2] start', ranges[2].start[1], 4)
assert_eq('hunks.ranges[2] end', ranges[2]['end'][1], 5)
vim.api.nvim_buf_delete(hunk_buf, { force = true })

-- Mason-lspconfig excludes stylua LSP and global formatexpr uses KickstartFormatexpr
assert_eq('global formatexpr wired', vim.o.formatexpr, 'v:lua.KickstartFormatexpr()')

print(string.format('format.markdown: %d checks passed', pass))
