return {
  {
    'weizheheng/ror.nvim',
    opts = function()
      return {}
    end,
    cond = function()
      return #vim.fn.exepath 'ruby' > 0
    end,
    lazy = true,
  },
}
