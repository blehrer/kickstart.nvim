local M = {}

function M.setup()
  local augend = require('dial.augend')
  local default = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.date.alias['%Y/%m/%d'],
    augend.constant.alias.bool,
  }

  local function with_default(extra)
    return vim.list_extend(vim.deepcopy(default), extra)
  end

  require('dial.config').augends:register_group({ default = default })

  require('dial.config').augends:on_filetype({
    markdown = with_default({ augend.misc.alias.markdown_header }),
    javascript = with_default({ augend.constant.new({ elements = { 'let', 'const' } }) }),
    typescript = with_default({ augend.constant.new({ elements = { 'let', 'const' } }) }),
    typescriptreact = with_default({ augend.constant.new({ elements = { 'let', 'const' } }) }),
    javascriptreact = with_default({ augend.constant.new({ elements = { 'let', 'const' } }) }),
  })

  local map = require('dial.map')
  vim.keymap.set('n', '<C-a>', function()
    map.manipulate('increment', 'normal')
  end, { desc = 'Increment' })
  vim.keymap.set('n', '<C-x>', function()
    map.manipulate('decrement', 'normal')
  end, { desc = 'Decrement' })
  vim.keymap.set('x', '<C-a>', function()
    map.manipulate('increment', 'visual')
  end, { desc = 'Increment' })
  vim.keymap.set('x', '<C-x>', function()
    map.manipulate('decrement', 'visual')
  end, { desc = 'Decrement' })
end

return M
