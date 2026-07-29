---@module "lazy"
---@type LazySpec
return {
  'afewyards/codereview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = {
    'CodeReview',
    'CodeReviewAuth',
    'CodeReviewAI',
    'CodeReviewAIFile',
    'CodeReviewStart',
    'CodeReviewSubmit',
    'CodeReviewApprove',
    'CodeReviewOpen',
    'CodeReviewPipeline',
    'CodeReviewComments',
    'CodeReviewFiles',
    'CodeReviewToggleScroll',
    'CodeReviewCommits',
  },
  ---@module "codereview"
  ---@type fun(): codereview.Config
  opts = function()
    return {
      base_url = 'gitlab.disney.com',
      gitlab_token = (vim.system { 'op', 'read', 'op://Employee/GITLAB_API_TOKEN/credential' }):wait().stdout,
      ai = {
        provider = 'cursor',
        custom_cmd = {
          cmd = '~/.local/bin/agent',
          args = { '--format', 'stream-json' },
        },
      },
    }
  end,
  ---@type LazyKeysSpec[]
  keys = {
    { '<leader>m', '<cmd>CodeReview<cr>', desc = 'Select MR' },
  },
}
