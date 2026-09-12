local md = require('format.markdown')

local pass = 0
local fail = 0

local function assert_eq(label, got, want)
  if got ~= want then
    fail = fail + 1
    error(label .. ': expected ' .. vim.inspect(want) .. ', got ' .. vim.inspect(got))
  end
  pass = pass + 1
end

local function assert_lines(label, got, want)
  if vim.deep_equal(got, want) then
    pass = pass + 1
    return
  end
  fail = fail + 1
  error(label .. ':\n  got  ' .. vim.inspect(got) .. '\n  want ' .. vim.inspect(want))
end

local function assert_atomic_links(label, lines)
  for _, ln in ipairs(lines) do
    local open = 0
    for i = 1, #ln do
      local ch = ln:sub(i, i)
      if ch == '[' then
        open = open + 1
      elseif ch == ']' then
        open = open - 1
        if open < 0 then
          error(label .. ': unmatched ] in ' .. vim.inspect(ln))
        end
      end
    end
    if open ~= 0 then
      error(label .. ': link split across line ' .. vim.inspect(ln))
    end
    if ln:find('%[', 1, true) and not ln:find('%b[]%b()', 1) and not ln:find('%[%[[^%]]+%]%]', 1) then
      error(label .. ': partial link on line ' .. vim.inspect(ln))
    end
  end
  pass = pass + 1
end

assert_lines(
  'table rows stay intact',
  md.format_line_range({
    '| Header one | Header two |',
    '| --- | --- |',
    '| alpha | beta gamma delta |',
  }, { width = 12 }),
  {
    '| Header one | Header two |',
    '| --- | --- |',
    '| alpha | beta gamma delta |',
  }
)

local function contains(lines, pattern)
  for _, ln in ipairs(lines) do
    if ln:find(pattern, 1) then
      return true
    end
  end
  return false
end

local link = '[a long link label](https://example.com/path)'
local wrapped = md.format_line_range({
  'Intro ' .. string.rep('word ', 8) .. link .. ' tail.',
}, { width = 50 })
assert_atomic_links('inline link not split', wrapped)
assert_eq('inline link present', contains(wrapped, '%[a long link label%]%(https://example%.com/path%)'), true)

local image = '![diagram](assets/foo.png)'
wrapped = md.format_line_range({
  'See ' .. string.rep('detail ', 10) .. image .. ' below.',
}, { width = 45 })
assert_atomic_links('inline image not split', wrapped)
assert_eq('inline image present', contains(wrapped, '!%[diagram%]%(assets/foo%.png%)'), true)

wrapped = md.format_line_range({
  'Follow ' .. string.rep('the ', 12) .. '[[Project Notes]] guide.',
}, { width = 40 })
assert_atomic_links('wiki link not split', wrapped)
assert_eq('wiki link present', contains(wrapped, '%[%[Project Notes%]%]'), true)

print(string.format('format.markdown: %d passed, %d failed', pass, fail))
if fail > 0 then
  os.exit(1)
end
