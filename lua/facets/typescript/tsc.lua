local M = {}

M.id = 'typescript.tsc'
M.requires = { 'node' }

M.trouble = {
  label = 'TypeScript (tsc --noEmit)',
  runner = 'tsc',
}

function M.detect(ctx)
  return vim.fn.filereadable(ctx.root .. '/tsconfig.json') == 1
    or vim.fn.filereadable(ctx.root .. '/tsconfig.build.json') == 1
end

return M
