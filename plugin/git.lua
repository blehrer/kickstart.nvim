vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/NeogitOrg/neogit',
  'https://github.com/afewyards/codereview.nvim',
})

require('gitsigns').setup()

require('neogit').setup({
  integrations = { snacks = true },
})

require('codereview').setup({
  picker = 'snacks',
  -- SECURITY-REVIEW: set tokens via environment or op:// in your local override
  github_token = vim.env.GITHUB_TOKEN,
  gitlab_token = vim.env.GITLAB_TOKEN,
})

vim.keymap.set('n', '<leader>gs', function()
  require('neogit').open()
end, { desc = 'Git status (neogit)' })

vim.keymap.set('n', '<leader>gm', '<cmd>CodeReview<cr>', { desc = 'Code review MR/PR' })

local function prompt_for_rendered_md_diff(args)
  if not (vim.wo.diff or vim.b[args.buf].codereview_enabled) then
    return
  end
  -- Short delay lets Neovim finish drawing the diff windows before the popup appears.
  vim.defer_fn(function()
    vim.ui.select({ 'Yes, open browser diff', 'No, keep reading in Neovim' }, {
      prompt = '📝 Markdown Diff Detected! Open in browser?',
    }, function(choice)
      if choice ~= 'Yes, open browser diff' then
        return
      end
      local file_path = vim.api.nvim_buf_get_name(args.buf)
      -- SECURITY-REVIEW: file_path comes from the current buffer name, not external input
      if vim.fn.has('mac') == 1 then
        vim.fn.jobstart({ 'open', file_path })
      elseif vim.fn.has('unix') == 1 then
        vim.fn.jobstart({ 'xdg-open', file_path })
      else
        vim.ui.open(file_path)
      end
      vim.notify('Opening browser view...', vim.log.levels.INFO)
    end)
  end, 100)
end

vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('CodeReviewMarkdownPopup', { clear = true }),
  pattern = 'codereview',
  callback = prompt_for_rendered_md_diff,
})

vim.api.nvim_create_user_command('RichMarkdownDiff', function()
  prompt_for_rendered_md_diff({ buf = vim.api.nvim_get_current_buf() })
end, {})
