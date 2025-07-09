function copyPath()
  if vim.bo.filetype == 'oil' then
    local o = require 'oil'
    local dir = o.get_current_dir()
    local file = o.get_cursor_entry().parsed_name
    local fp = dir .. file
    vim.fn.setreg('+', fp)
    vim.notify('Copied "' .. fp .. '" to clipboard')
    return dir .. file
  end
end

vim.keymap.set({ 'n' }, '<leader>y', copyPath, { desc = 'Copy path to current Oil entry' })
