local function promptForRenderedMdDiff(args)
  -- Verify if this file is actively being controlled or viewed within a codereview session
  -- afewyards/codereview.nvim sets specific buffer variables or uses 'diff' windows
  if vim.wo.diff or vim.b[args.buf].codereview_enabled then
    -- Short delay ensures Neovim finishes drawing the windows before rendering the popup UI
    vim.defer_fn(function()
      local choices = { 'Yes, open browser diff', 'No, keep reading in Neovim' }

      vim.ui.select(choices, {
        prompt = '📝 Markdown Diff Detected! Open in browser?',
      }, function(choice)
        if choice == 'Yes, open browser diff' then
          -- 1. Grab the current file path
          local file_path = vim.api.nvim_buf_get_name(args.buf)

          -- 2. Execute a smart browser opening mechanism based on your OS
          -- (Falls back to the native vim.ui.open interface added in Neovim 0.10+)
          if vim.fn.has 'mac' == 1 then
            vim.fn.jobstart { 'open', file_path }
          elseif vim.fn.has 'unix' == 1 then
            vim.fn.jobstart { 'xdg-open', file_path }
          else
            -- Standard native neovim interface fallback
            vim.ui.open(file_path)
          end

          vim.notify('Opening browser view...', vim.log.levels.INFO)
        end
      end)
    end, 100) -- 100ms drawing delay
  end
end
-- Autocommand to intercept markdown diff buffers opened by codereview.nvim
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('CodeReviewMarkdownPopup', { clear = true }),
  pattern = 'codereview',
  callback = promptForRenderedMdDiff,
})

vim.api.nvim_create_user_command('RichMarkdownDiff', function()
  promptForRenderedMdDiff { buf = vim.api.nvim_get_current_buf() }
end, {})
