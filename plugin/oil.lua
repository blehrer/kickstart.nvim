if vim.g.vscode then return end

vim.pack.add({ 'https://github.com/stevearc/oil.nvim' })

require('oil').setup({
  preview_win = {
    update_on_cursor_moved = true,
    show_hidden = true,
  },
})

vim.keymap.set('n', '-', function()
  require('oil').open()
end, { desc = 'Open parent directory (oil)' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'oil',
  group = vim.api.nvim_create_augroup('nvim-new-oil', { clear = true }),
  callback = function(args)
    vim.keymap.set('n', '~', function()
      vim.api.nvim_set_current_dir(require('oil').get_current_dir(0) or '.')
    end, { buffer = args.buf, desc = 'Set cwd to Oil directory' })

    vim.keymap.set('n', '<leader>y', function()
      local oil = require('oil')
      local dir = oil.get_current_dir()
      if not dir then
        return
      end

      local entry = oil.get_cursor_entry()
      if not entry or entry.name == '..' or entry.id == 0 then
        return
      end

      local path = vim.fs.normalize(vim.fs.joinpath(dir, entry.parsed_name or entry.name))
      local cwd = vim.fs.normalize(vim.fn.getcwd())
      local rel = path

      local ok, result = pcall(vim.fs.relpath, cwd, path)
      if ok and result and result ~= '' and result ~= '.' then
        rel = result
      end

      if not vim.startswith(rel, '/') and not vim.startswith(rel, './') then
        rel = './' .. rel
      end

      vim.fn.setreg('+', rel)
      vim.fn.setreg('"', rel)
    end, { buffer = args.buf, desc = 'Copy path relative to cwd' })
  end,
})
