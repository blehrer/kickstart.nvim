return {
  -- {
  --   'Makaze/AnsiEsc',
  --   opts = {},
  -- },
  {
    'catgoose/nvim-colorizer.lua',
    event = 'BufReadPre',
    enabled = true,
    opts = { -- set to setup table
      user_default_options = {
        names = false,
        tailwind = true,
        xterm = true,
      },
    },
  },
}
