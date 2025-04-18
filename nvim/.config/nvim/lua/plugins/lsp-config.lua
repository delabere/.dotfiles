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
  -- "pbls", -- protobuf
  -- "buf_ls",
  -- "htmx",
  -- "tsserver",
}

-- vim.lsp.config("gopls", {
--   root_dir = lspconfig.util.root_pattern("main.go", "README.md", "LICENSE")(),
-- })
--

for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end

require("lspconfig").protols.setup({})
return {
  {
    dir = "~",
    enabled = path:new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev"):exists(),
    config = function()
      vim.lsp.config("gopls", {
        -- stops the lsp from trying to ingest the world
        cmd = { "env", "GO111MODULE=off", "gopls", "-remote=auto" },

        -- sets the root directory at the service level, which achieves two things:
        -- 1. Stops lsp from ingesting the world
        -- 2. Allows you to use <leader>sg for picker scoped to the service, and <leader>sG, for all of the monorepo
        root_dir = function(bufnr, cb)
          local buffer_filepath = vim.api.nvim_buf_get_name(bufnr)

          local root_markers = { "main.go", "README.md", "go.mod", "LICENSE" } -- Add more as needed
          local root_directory = lspconfig.util.root_pattern(root_markers)(buffer_filepath, bufnr)
          cb(root_directory)
        end,
        --
        filetypes = { "go", "yml", "proto" },
      })
    end,
  },
}
