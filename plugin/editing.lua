vim.pack.add({
  'https://github.com/windwp/nvim-autopairs',
  'https://github.com/monaqa/dial.nvim',
  'https://github.com/gaoDean/autolist.nvim',
})

require('nvim-autopairs').setup({})

local augend = require('dial.augend')
require('dial.config').augends:register_group({
  default = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.date.alias['%Y/%m/%d'],
    augend.constant.alias.bool,
  },
})

vim.g.dials_by_ft = {
  markdown = 'markdown',
  javascript = 'typescript',
  typescript = 'typescript',
  typescriptreact = 'typescript',
  javascriptreact = 'typescript',
}

require('dial.config').augends:register_group({
  markdown = { augend.misc.alias.markdown_header },
  typescript = { augend.constant.new({ elements = { 'let', 'const' } }) },
})

local function dial(increment, g)
  local mode = vim.fn.mode(true)
  local is_visual = mode == 'v' or mode == 'V' or mode == '\22'
  local func = (increment and 'inc' or 'dec') .. (g and '_g' or '_') .. (is_visual and 'visual' or 'normal')
  local group = vim.g.dials_by_ft[vim.bo.filetype] or 'default'
  return require('dial.map')[func](group)
end

vim.keymap.set({ 'n', 'v' }, '<C-a>', function()
  return dial(true)
end, { expr = true, desc = 'Increment' })
vim.keymap.set({ 'n', 'v' }, '<C-x>', function()
  return dial(false)
end, { expr = true, desc = 'Decrement' })

require('autolist').setup({})

local list_fts = { 'markdown', 'text', 'tex', 'plaintex' }
vim.api.nvim_create_autocmd('FileType', {
  pattern = list_fts,
  group = vim.api.nvim_create_augroup('autolist-keys', { clear = true }),
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('i', '<CR>', '<CR><cmd>AutolistNewBullet<cr>', opts)
    vim.keymap.set('n', '<CR>', '<cmd>AutolistToggleCheckbox<cr><CR>', opts)
  end,
})
