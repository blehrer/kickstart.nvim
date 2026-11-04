if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/3rd/image.nvim',
  'https://github.com/ducks/vimdeck.nvim',
})

require('render-markdown').setup({
  file_types = { 'markdown', 'vimwiki' },
})

require('image').setup({
  backend = 'kitty',
  integrations = {
    markdown = {
      enabled = true,
      clear_in_insert_mode = false,
      download_remote_images = true,
      only_render_image_at_cursor = false,
    },
  },
})

require('vimdeck').setup({
  use_figlet = false,
  center_vertical = true,
  center_horizontal = false,
})
