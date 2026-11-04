vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('nvim-new-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Tint the merge-target buffer's background while it's shown in a diff split
vim.api.nvim_set_hl(0, 'MergeTargetBackground', { bg = '#a6a6a6', default = true })
vim.api.nvim_create_autocmd('OptionSet', {
  pattern = 'diff',
  callback = function()
    if vim.v.option_new == '1' then
      local tgt = vim.g.tgt_buf
      local current_buf = vim.api.nvim_get_current_buf()
      if tgt and current_buf == tgt then
        vim.wo.winhighlight = 'Normal:MergeTargetBackground,NormalNC:MergeTargetBackground'
      end
    else
      vim.wo.winhighlight = ''
    end
  end,
})
