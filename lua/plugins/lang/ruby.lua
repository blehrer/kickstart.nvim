return {
  {
    'weizheheng/ror.nvim',
    opts = {},
    cond = function()
      return #vim.fn.exepath 'ruby' > 0
    end,
    lazy = true,
  },
}
