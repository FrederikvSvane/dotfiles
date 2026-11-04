-- Make sure Mason installs ty (selected via vim.g.lazyvim_python_lsp in options.lua).
return {
  { "mason-org/mason.nvim", opts = { ensure_installed = { "ty" } } },
}
