vim.filetype.add {
  filename = {
    ['build.gradle.kts'] = 'kotlin.gradle',
    ['build.gradle'] = 'groovy.gradle',
  },
}
vim.lsp.enable 'gradle_ls'
