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
  -- "yaml-language-server",
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

      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            format = {
              enable = true,
            },
            schemas = {
              [vim.fn.expand("~") .. "/src/github.com/monzo/wearedev/libraries/cassandra/schema/schema.bundled.generated.json"] = "*/config/schema.yml",
            },
          },
        },
      })
      vim.lsp.enable("yamlls")

      -- Command to toggle between service-scoped and global LSP root
      vim.api.nvim_create_user_command("LspToggleGlobalRoot", function()
        helpers.use_global_lsp_root = not helpers.use_global_lsp_root
        local mode = helpers.use_global_lsp_root and "global (wearedev)" or "service-scoped"
        vim.notify("LSP root mode: " .. mode, vim.log.levels.INFO)

        -- Restart gopls to apply new root directory
        vim.cmd("LspRestart gopls")
      end, { desc = "Toggle between service-scoped and global LSP root" })
    end,
  },
}
