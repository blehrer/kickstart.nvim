local hammerspoon_annotations = vim.fn.expand('~/.hammerspoon/Spoons/EmmyLua.spoon/annotations')
local hammerspoon_dir = vim.fn.expand('~/.hammerspoon')

return {
  settings = {
    Lua = {
      format = { enable = false },
    },
  },
  on_attach = function(client, bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == '' or not path:find(hammerspoon_dir, 1, true) then
      return
    end

    local library = {}
    if vim.uv.fs_stat(hammerspoon_annotations) then
      table.insert(library, hammerspoon_annotations)
    end

    if #library == 0 then
      return
    end

    client.notify('workspace/didChangeConfiguration', {
      settings = {
        Lua = {
          diagnostics = { globals = { 'hs', 'spoon' } },
          workspace = { library = library },
        },
      },
    })
  end,
}
