local lspconfig = require("lspconfig")
local path = require("plenary.path")
local helpers = require("config.helpers")

local servers = {
  "pyright",
  "marksman",
  -- "kotlin_language_server",
  -- "templ",
  -- "html",
  "svelte",
  "gopls",
  -- "protols",
  -- "pbls", -- protobuf
  -- "buf_ls",
  -- "htmx",
  -- "tsserver",
}

for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end

return {
  {
    dir = "~",
    enabled = path:new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev"):exists(),
    config = function()
      vim.lsp.config("gopls", {
        -- cmd = { "env", "GO111MODULE=off", "gopls", "-remote=auto" },
        cmd = { "env", "GO111MODULE=off", "gopls", "-remote=auto" },
        -- cmd = { "env", "GO111MODULE=off", "gopls", "-remote=auto", "-rpc.trace", "serve", "--debug=localhost:6060" },
        root_dir = helpers.service_root_dir_lsp,
        filetypes = { "go", "yml" },
      })

      -- vim.lsp.config("protols", {
      --   root_dir = helpers.service_root_dir_lsp,
      -- })

      vim.lsp.config("protols_go", {
        cmd = { "protols", "serve", "--stdio", "--default-log-level", "info" },
        filetypes = { "proto" },
        root_markers = { ".git" },
      })

      vim.lsp.enable("protols_go")
    end,
  },
}
