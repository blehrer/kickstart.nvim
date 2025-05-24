-- remove conflicts with window manager
local alt = function(k)
  return vim.keycode(('<M-%s>'):format(k))
end
local alt_shift = function(k)
  return vim.keycode(('<M-S-%s>'):format(k))
end
local ctrl_alt_shift = function(k)
  return vim.keycode(('<C-M-S-%s>'):format(k))
end
for _, key in ipairs { 'y', 'u', 'i', 'o', 'p' } do
  pcall(function()
    vim.keymap.del({ 'n', 'v', 'i', 'x' }, alt(key))
  end)
  pcall(function()
    vim.keymap.del({ 'n', 'v', 'i', 'x' }, alt_shift(key))
  end)
  pcall(function()
    vim.keymap.del({ 'n', 'v', 'i', 'x' }, ctrl_alt_shift(key))
  end)
end
