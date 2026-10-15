-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Python host for molten.nvim (created by setup.sh); leave the default if absent.
local host = vim.fn.stdpath("data") .. "/python-host"
if vim.fn.isdirectory(host) == 1 then
  vim.g.python3_host_prog = host .. "/bin/python"
end
