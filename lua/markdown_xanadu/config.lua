local M = {}

---@return table
function M.get()
  local defaults = {
    root = nil,
    sidebar_width = 0.22,
    embed_width = 0.45,
    follow = true,
    max_open_embeds = 3,
  }
  return vim.tbl_deep_extend('force', defaults, vim.g.markdown_xanadu or {})
end

---@param bufnr? integer
---@return string
function M.fixture_root(bufnr)
  local cfg = M.get()
  if cfg.root and cfg.root ~= '' then
    return vim.fn.fnamemodify(cfg.root, ':p')
  end
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name ~= '' then
      local git = vim.fs.find('.git', { upward = true, path = name, limit = 1 })[1]
      if git then
        return vim.fn.fnamemodify(git, ':h')
      end
      return vim.fn.fnamemodify(name, ':h')
    end
  end
  local git = vim.fs.find('.git', { upward = true, path = vim.loop.cwd(), limit = 1 })[1]
  if git then
    return vim.fn.fnamemodify(git, ':h')
  end
  return vim.loop.cwd()
end

---@return string
function M.corpus_root()
  local cfg = M.get()
  if cfg.root and cfg.root ~= '' then
    return vim.fn.fnamemodify(cfg.root, ':p')
  end
  local repo = vim.fs.find('.git', { upward = true, path = vim.loop.cwd(), limit = 1 })[1]
  local base = repo and vim.fn.fnamemodify(repo, ':h') or vim.loop.cwd()
  local fixture = base .. '/test/fixtures/markdown_xanadu'
  if vim.uv.fs_stat(fixture) then
    return fixture
  end
  return base
end

return M
