--- Alt+number in terminal Neovim on macOS often inserts US Option chars (¡ ™ …)
--- instead of <A-N> when the emulator is not set to Option-as-Meta.
local M = {}

local US_OPTION = {
  ['0'] = 'º',
  ['1'] = '¡',
  ['2'] = '™',
  ['3'] = '£',
  ['4'] = '¢',
  ['5'] = '∞',
  ['6'] = '§',
  ['7'] = '¶',
  ['8'] = '•',
  ['9'] = 'ª',
}

function M.set(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, opts)
  if vim.fn.has('mac') ~= 1 or vim.fn.has('gui_running') == 1 then
    return
  end
  local digit = lhs:match('<[AM]%-(%d)>$')
  local ch = digit and US_OPTION[digit]
  if ch then
    vim.keymap.set(mode, ch, rhs, vim.tbl_extend('force', opts or {}, {
      desc = (opts and opts.desc or lhs) .. ' (Mac Option)',
    }))
  end
end

return M
