local M = {}

M.pass = 0
M.fail = 0
M.errors = {}

local ROOT = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h:h')

function M.reset()
  M.pass = 0
  M.fail = 0
  M.errors = {}
end

function M.corpus_root()
  return ROOT .. '/test/fixtures/markdown_xanadu'
end

function M.with_root(fn)
  local prev = vim.g.markdown_xanadu
  vim.g.markdown_xanadu = vim.tbl_deep_extend('force', prev or {}, {
    root = M.corpus_root(),
  })
  local ok, err = pcall(fn)
  vim.g.markdown_xanadu = prev
  if not ok then
    error(err)
  end
end

---@param rel string
---@return integer bufnr
function M.load_fixture(rel)
  local path = M.corpus_root() .. '/' .. rel
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then
    error('fixture not found: ' .. path)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = 'markdown'
  vim.bo[buf].bufhidden = 'wipe'
  return buf
end

local function deep_equal(a, b)
  if a == b then
    return true
  end
  if type(a) ~= 'table' or type(b) ~= 'table' then
    return false
  end
  for k, v in pairs(a) do
    if not deep_equal(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

function M.assert_true(name, cond, msg)
  if cond then
    M.pass = M.pass + 1
  else
    M.fail = M.fail + 1
    M.errors[#M.errors + 1] = name .. ': ' .. (msg or 'assertion failed')
  end
end

function M.assert_eq(name, got, expect)
  if deep_equal(got, expect) then
    M.pass = M.pass + 1
  else
    M.fail = M.fail + 1
    M.errors[#M.errors + 1] = ('%s: got %s expect %s'):format(
      name,
      vim.inspect(got),
      vim.inspect(expect)
    )
  end
end

function M.assert_suffix(name, got_path, suffix)
  if got_path and got_path:find(suffix, 1, true) then
    M.pass = M.pass + 1
  else
    M.fail = M.fail + 1
    M.errors[#M.errors + 1] = ('%s: path %s missing suffix %s'):format(name, tostring(got_path), suffix)
  end
end

function M.run_spec(name, fn)
  M.with_root(function()
    fn()
  end)
end

return M
