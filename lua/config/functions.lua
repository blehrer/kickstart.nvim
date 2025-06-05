function Inspect(obj)
  vim.notify(vim.inspect(obj))
end

function HasChezmoi()
  return vim.system({ 'command', '-v', 'chezmoi' }):wait().code == 0
end
