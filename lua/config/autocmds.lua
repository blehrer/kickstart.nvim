vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('nvim-new-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('nvim-new-lsp-attach', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local group = vim.api.nvim_create_augroup('nvim-new-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('nvim-new-lsp-detach', { clear = true }),
        callback = function(detach_event)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({ group = 'nvim-new-lsp-highlight', buffer = detach_event.buf })
        end,
      })
    end
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
