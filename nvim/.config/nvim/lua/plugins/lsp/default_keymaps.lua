local setup_keymaps = function(_, bufnr)
  local opts = { noremap = true, silent = true }
  local keymap = vim.keymap -- for conciseness
  opts.buffer = bufnr

  opts.desc = "Show LSP definitions"
  keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

  opts.desc = "Show LSP references"
  keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)

  opts.desc = "Show documentation for what is under cursor"
  keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)

  opts.desc = "Show LSP implementations"
  keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

  opts.desc = "Show LSP type definitions"
  keymap.set("n", "gt", "<cmd> lua vim.lsp.buf.type_definition()<CR>", opts)

  opts.desc = "Smart rename"
  keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)

  opts.desc = "See available code actions"
  keymap.set("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)

  opts.desc = "LSP format"
  keymap.set("n", "<leader>lf", "<cmd>lua vim.lsp.buf.format()<CR>", opts)

  opts.desc = "LSP info"
  keymap.set("n", "<leader>li", "<cmd>LspInfo<CR>", opts)

  opts.desc = "Show buffer diagnostics"
  keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

  opts.desc = "Go to previous diagnostic"
  keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

  opts.desc = "Go to next diagnostic"
  keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

  -- these aren't LSP specific, but it makes sense to only add them on attach to gopls
  opts.desc = "See available code actions"
  vim.keymap.set("n", "<Leader>b", "<cmd>GoBuild<cr>")

  opts.desc = "See available code actions"
  vim.keymap.set("n", "<Leader>t", "<cmd>GoTest<cr>")

  opts.desc = "See available code actions"
  vim.keymap.set("n", "<Leader>x", "<cmd>GoCodeAction<cr>")

  opts.desc = "See available code actions"
  vim.keymap.set("v", "<Leader>x", "<cmd>GoCodeAction<cr>")

  opts.desc = "Restart LSP"
  keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
  --
  -- Workaround for the lack of a DAP strategy in neotest-go: https://github.com/nvim-neotest/neotest-go/issues/12
  opts.desc = "Debug nearest test (Go)"
  keymap.set("", "<leader>td", "<cmd>lua require('dap-go').debug_test()<CR>", opts)
  -- this line 👇 tells lspconfig to ignore all the above mappings and instead use those
  -- provided by the navigator plugin
  -- require("navigator.lspclient.mapping").setup({ bufnr = bufnr, client = client })
end

return {
  setup_keymaps = setup_keymaps,
}
