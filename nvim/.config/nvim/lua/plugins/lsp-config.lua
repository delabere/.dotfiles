local lspconfig = require("lspconfig")
local path = require("plenary.path")

local servers = {
  "pyright",
  "marksman",
  -- "kotlin_language_server",
  -- "templ",
  -- "html",
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

local function service_root_dir(bufnr, cb)
  local buffer_filepath = vim.api.nvim_buf_get_name(bufnr)
  local root_markers = { "main.go", "README.md", "go.mod", "LICENSE" } -- Add more as needed
  local root_directory = lspconfig.util.root_pattern(root_markers)(buffer_filepath)
  cb(root_directory)
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
        root_dir = service_root_dir,
        filetypes = { "go", "yml" },
        -- verboseOutput = true, -- should provide better logging
      })

      -- vim.lsp.enable("gopls2")
      -- vim.lsp.config("gopls2", {
      --   -- cmd = { "env", "GO111MODULE=off", "gopls", "-remote=auto" },
      --   cmd = { "gopls", "-remote=auto" },
      --   -- cmd = { "env", "GO111MODULE=off", "gopls", "-remote=auto", "-rpc.trace", "serve", "--debug=localhost:6060" },
      --   -- root_dir = service_root_dir,
      --   filetypes = { "go", "yml" },
      --   -- verboseOutput = true, -- should provide better logging
      -- })

      vim.lsp.config("protols", {
        root_dir = service_root_dir,
      })
    end,
  },
}
