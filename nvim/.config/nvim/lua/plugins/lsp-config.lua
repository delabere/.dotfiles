local lspconfig = require("lspconfig")
local path = require("plenary.path")

local servers = {
  "pyright",
  "marksman",
  "kotlin_language_server",
  "templ",
  "html",
  "svelte",
  "gopls",
  -- "htmx",
  -- "tsserver",
}
for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end

return {
  {
    dir = "~/src/github.com/monzo/wearedev/tools/editors/nvim/nvim-monzo",
    enabled = path:new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev"):exists(),
    config = function()
      vim.lsp.config("gopls", {
        root_dir = lspconfig.util.root_pattern("main.go", "README.md", "LICENSE")(),
      })
    end,
  },
}
