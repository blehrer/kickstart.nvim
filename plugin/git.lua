if vim.g.vscode then return end

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

local gitlab_token_cache ---@type string|false|nil

local function ensure_gitlab_token()
  if vim.env.GITLAB_TOKEN and vim.env.GITLAB_TOKEN ~= '' then
    return true
  end
  if gitlab_token_cache == false then
    return false
  end
  if gitlab_token_cache then
    vim.env.GITLAB_TOKEN = gitlab_token_cache
    return true
  end
  -- SECURITY-REVIEW: token fetched from 1Password CLI on first CodeReview use
  local result = vim.system({ 'op', 'read', 'op://Employee/GITLAB_API_TOKEN/credential' }):wait()
  local token = result.code == 0 and result.stdout and vim.trim(result.stdout) or ''
  gitlab_token_cache = token ~= '' and token or false
  if token ~= '' then
    vim.env.GITLAB_TOKEN = token
    return true
  end
  return false
end

require('codereview').setup({
  picker = 'snacks',
  base_url = 'https://gitlab.disney.com',
  github_token = vim.env.GITHUB_TOKEN,
  ai = {
    provider = 'custom_cmd',
    custom_cmd = {
      cmd = vim.fn.expand('~/.local/bin/agent'),
      args = { '-p', '--output-format', 'text' },
    },
  },
})

vim.keymap.set('n', '<leader>gs', function()
  require('neogit').open()
end, { desc = 'Git status (neogit)' })

vim.keymap.set('n', '<leader>gm', function()
  if not ensure_gitlab_token() then
    vim.notify('GitLab token unavailable (set GITLAB_TOKEN or sign in to 1Password)', vim.log.levels.WARN)
    return
  end
  vim.cmd.CodeReview()
end, { desc = 'Code review MR/PR' })

vim.api.nvim_create_autocmd('CmdlineChanged', {
  group = vim.api.nvim_create_augroup('CodeReviewGitLabToken', { clear = true }),
  callback = function()
    if vim.env.GITLAB_TOKEN and vim.env.GITLAB_TOKEN ~= '' then
      return
    end
    if vim.fn.getcmdline():match('^CodeReview') then
      ensure_gitlab_token()
    end
  end,
})

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
