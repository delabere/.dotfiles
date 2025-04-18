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
  "protols",
  -- "pbls", -- protobuf
  -- "buf_ls",
  -- "htmx",
  -- "tsserver",
}

for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end

-- service_root_dir is used to determine the root directory for the LSP server and
-- can be used if the default root finding might cause issues, for example in a large monorepo
local function service_root_dir(bufnum, callback)
  local buffer_filepath = vim.api.nvim_buf_get_name(bufnum)
  local root_markers = { "main.go", "README.md", "go.mod", "LICENSE" }
  local root_directory = lspconfig.util.root_pattern(root_markers)(buffer_filepath)
  callback(root_directory)
end

-- if we are in the monorepo, we want our lsps set up differently
local monorepo_dir = path:new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev")
if monorepo_dir:exists() then
  vim.lsp.config("gopls", {
    cmd = { "env", "GO111MODULE=off", "gopls", "-remote=auto" },
    root_dir = service_root_dir,
    filetypes = { "go", "yml" },
  })

  vim.lsp.config("protols", {
    root_dir = service_root_dir,
  })
end

return {}
