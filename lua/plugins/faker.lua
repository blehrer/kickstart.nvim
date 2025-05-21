---@module 'lazy.types'
---@type LazyPluginSpec
return {
  'tehdb/nvim-faker',
  lazy = true,
  build = function(_)
    os.execute 'npm i -g @tehdb/faker-cli'
  end,
  opts = {
    use_global_package = true, -- use global npm package otherwise npx (default: false)
  },
}
