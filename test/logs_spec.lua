local logs = require('config.logs')

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, 'p')

-- 1. Unknown log is pruned
local stale = tmp .. '/noice.log'
vim.fn.writefile({ 'old log line' }, stale)

-- 2. Small known log is untouched
local small = tmp .. '/lsp.log'
vim.fn.writefile({ 'line 1', 'line 2' }, small)

-- 3. Oversized known log is truncated to keep_bytes and aligned to newline
local big = tmp .. '/neotest.log'
local lines = {}
for i = 1, 200 do
  lines[i] = ('entry-%04d: %s'):format(i, string.rep('x', 40))
end
vim.fn.writefile(lines, big)

-- 4. Non-log file is ignored
local other = tmp .. '/trust'
vim.fn.writefile({ 'keep me' }, other)

local res = logs.maintain(tmp, { max_bytes = 2000, keep_bytes = 500 })

assert(#res.pruned == 1 and res.pruned[1] == 'noice.log', 'pruned noice.log')
assert(vim.uv.fs_stat(stale) == nil, 'stale unlinked')
assert(vim.uv.fs_stat(other) ~= nil, 'non-log preserved')
assert(vim.uv.fs_stat(small).size < 100, 'small log preserved')
assert(#res.truncated == 1 and res.truncated[1] == 'neotest.log', 'truncated neotest.log')

local big_stat = vim.uv.fs_stat(big)
assert(big_stat and big_stat.size <= 500, 'big log capped to keep_bytes')
local kept = vim.fn.readfile(big)
assert(#kept > 0 and kept[1]:match('^entry%-0'), 'aligned to full line start')
assert(kept[#kept]:match('^entry%-0200:'), 'preserved newest line')

vim.fn.delete(tmp, 'rf')
print('logs: 7 checks passed')
