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
    end
  end,
})
