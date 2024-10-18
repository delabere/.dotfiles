local on_attach_omnisharp = function(_, bufnr)
  local opts = { noremap = true, silent = true }
  local keymap = vim.keymap -- for conciseness
  opts.buffer = bufnr

  opts.desc = "Show LSP definitions"
  keymap.set(
    "n",
    "gd",
    "<cmd>lua require('omnisharp_extended').telescope_lsp_definition({ jump_type = 'vsplit' })<cr>",
    opts
  )

  opts.desc = "Show LSP references"
  keymap.set("n", "gr", "<cmd>lua require('omnisharp_extended').telescope_lsp_references()<cr>", opts)

  opts.desc = "Show documentation for what is under cursor"
  keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)

  opts.desc = "Show LSP implementations"
  keymap.set("n", "gi", "<cmd>lua require('omnisharp_extended').telescope_lsp_implementation()<cr>", opts)

  opts.desc = "Show LSP type definitions"
  keymap.set("n", "gt", "<cmd>lua require('omnisharp_extended').telescope_lsp_type_definition()<cr>", opts)

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
  cmd = { "omnisharp" },
  on_attach = on_attach_omnisharp,
  settings = {
    FormattingOptions = {
      -- Enables support for reading code style, naming convention and analyzer
      -- settings from .editorconfig.
      EnableEditorConfigSupport = true,
      -- Specifies whether 'using' directives should be grouped and sorted during
      -- document formatting.
      OrganizeImports = nil,
    },
    MsBuild = {
      -- If true, MSBuild project system will only load projects for files that
      -- were opened in the editor. This setting is useful for big C# codebases
      -- and allows for faster initialization of code navigation features only
      -- for projects that are relevant to code that is being edited. With this
      -- setting enabled OmniSharp may load fewer projects and may thus display
      -- incomplete reference lists for symbols.
      LoadProjectsOnDemand = nil,
    },
    RoslynExtensionsOptions = {
      -- Enables support for roslyn analyzers, code fixes and rulesets.
      EnableAnalyzersSupport = nil,
      -- Enables support for showing unimported types and unimported extension
      -- methods in completion lists. When committed, the appropriate using
      -- directive will be added at the top of the current file. This option can
      -- have a negative impact on initial completion responsiveness,
      -- particularly for the first few completion sessions after opening a
      -- solution.
      EnableImportCompletion = nil,
      -- Only run analyzers against open files when 'enableRoslynAnalyzers' is
      -- true
      AnalyzeOpenDocumentsOnly = nil,
    },
    Sdk = {
      -- Specifies whether to include preview versions of the .NET SDK when
      -- determining which version to use for project loading.
      IncludePrereleases = true,
    },
  },
}
