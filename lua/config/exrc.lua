-- Ask about untrusted exrc files (.nvim.lua, .nvimrc, .exrc), and files they
-- read with vim.secure.read, after startup. Nvim's own prompt runs before args
-- are opened, so choosing (v)iew splits the window before oil renders
-- `nvim .`, leaving an empty buffer focused.
-- Trusted and denied files still load (or not) during startup as usual.

local names = { ['.nvim.lua'] = true, ['.nvimrc'] = true, ['.exrc'] = true }
local read = vim.secure.read
local pending = {}

-- True unless the trust db already allows this exact content or denies the file.
local function needs_prompt(path)
  local fh = io.open(path, 'rb')
  if not fh then
    return false
  end
  local hash = vim.fn.sha256(fh:read('*a'))
  fh:close()
  local db = io.open(vim.fn.stdpath('state') .. '/trust')
  if not db then
    return true
  end
  for line in db:lines() do
    local h, p = line:match('^(%S+) (.+)$')
    if p == path and (h == hash or h == '!') then
      db:close()
      return false
    end
  end
  db:close()
  return true
end

-- Show `path` in a split and ask. Returns true if the user trusted it.
local function prompt(path)
  vim.cmd.split(vim.fn.fnameescape(path))
  vim.cmd.redraw()
  local choice = vim.fn.confirm('Untrusted code:\n' .. path, '&Trust\n&Not now\n&Deny', 2)
  if choice ~= 1 and choice ~= 3 then
    vim.notify('Left ' .. vim.fn.fnamemodify(path, ':~:.') .. ' open for review. :trust allows it from the next start.')
    return false
  end
  vim.secure.trust({ action = choice == 1 and 'allow' or 'deny', bufnr = 0 })
  vim.cmd.close()
  return choice == 1
end

---@diagnostic disable-next-line: duplicate-set-field
vim.secure.read = function(path)
  local full = vim.uv.fs_realpath(vim.fs.normalize(path))
  local caller = (debug.getinfo(2, 'S').source:match('^@(.+)')) or ''
  local is_exrc = full and names[vim.fs.basename(full)]
  if full and (is_exrc or names[vim.fs.basename(caller)]) and needs_prompt(full) then
    if vim.v.vim_did_enter == 0 then
      table.insert(pending, { path = full, exrc = is_exrc })
      return nil
    end
    if not prompt(full) then
      return nil
    end
  end
  return read(path)
end

local function redetect_filetypes()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' and vim.api.nvim_buf_get_name(buf) ~= '' then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd('filetype detect')
      end)
    end
  end
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    -- Let VimEnter handlers (oil, dashboards) draw first.
    vim.schedule(function()
      for _, item in ipairs(pending) do
        if prompt(item.path) then
          if item.exrc then
            vim.cmd.source(vim.fn.fnameescape(item.path))
            -- exrc files often add filetypes; apply them to buffers opened at startup.
            redetect_filetypes()
          else
            vim.notify('Trusted ' .. vim.fn.fnamemodify(item.path, ':~:.') .. '. Restart Neovim to apply it.')
          end
        end
      end
    end)
  end,
})
