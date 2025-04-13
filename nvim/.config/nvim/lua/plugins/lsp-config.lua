local lspconfig = require("lspconfig")
-- local cmp_nvim_lsp = require("cmp_nvim_lsp")
-- local keymaps = require("plugins.lsp.default_keymaps")

-- get the work directory as a plenary path
-- local path = require("plenary.path")
-- local p = path:new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev")
-- -- Check if the directory exists
-- local work_profile = p:exists()
-- -- for work, we have a specific setup for our language server
--
-- local dependencies = { "saghen/blink.cmp" }
-- if work_profile == true then
--   table.insert(dependencies, { dir = "~/src/github.com/monzo/wearedev/tools/editors/nvim/nvim-monzo" })
-- end

-- require("plugins.lsp.gopls")

-- vim.lsp.enable("gopls")
-- configure all our other servers
local servers = {
  "pyright",
  "marksman",
  "kotlin_language_server",
  "templ",
  "html",
  "svelte",
  -- "htmx",
  -- "tsserver",
}
for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end

return {
  {
    dir = "~/src/github.com/monzo/wearedev/tools/editors/nvim/nvim-monzo",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      local path = require("plenary.path")
      if path:new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev"):exists() then
        vim.lsp.config("gopls", {
          root_dir = lspconfig.util.root_pattern("main.go", "README.md", "LICENSE")(),
        })
        vim.lsp.enable("gopls")
      end
    end,
  },
}
--   {
--     "neovim/nvim-lspconfig",
--     event = { "BufReadPre", "BufNewFile" },
--     dependencies = dependencies,
--     config = function()
--       local capabilities = require("blink.cmp").get_lsp_capabilities()
--       -- local capabilities = cmp_nvim_lsp.default_capabilities()
--       -- Change the Diagnostic symbols in the sign column (gutter)
--       local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
--       for type, icon in pairs(signs) do
--         local hl = "DiagnosticSign" .. type
--         vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
--       end
--
--       -- servers with special config
--       require("lspconfig")["gopls"].setup(require("plugins.lsp.go").get_opts(keymaps.setup_keymaps, capabilities))
--       require("lspconfig").lua_ls.setup(require("plugins.lsp.lua"))
--
--       -- configure all our other servers
--       local servers = {
--         "pyright",
--         -- "tsserver",
--         "marksman",
--         "kotlin_language_server",
--         "templ",
--         -- "htmx",
--         "html",
--         "svelte",
--       }
--       for _, lsp in ipairs(servers) do
--         require("lspconfig")[lsp].setup({
--           on_attach = keymaps.setup_keymaps,
--           capabilities = capabilities,
--           root_dir = lspconfig.util.root_pattern("main.go", "README.md", "go.mod", "LICENSE"),
--         })
--       end
--     end,
--   },
--
--   {
--     "mrcjkb/rustaceanvim",
--     version = "^3",
--     dependencies = {
--       "nvim-lua/plenary.nvim",
--       "mfussenegger/nvim-dap",
--       {
--         "lvimuser/lsp-inlayhints.nvim",
--         opts = {},
--       },
--     },
--     ft = { "rust" },
--     config = function()
--       vim.g.rustaceanvim = {
--         inlay_hints = {
--           highlight = "NonText",
--         },
--         tools = {
--           hover_actions = {
--             auto_focus = true,
--           },
--         },
--         server = {
--           on_attach = function(client, bufnr)
--             require("lsp-inlayhints").on_attach(client, bufnr)
--             keymaps.setup_keymaps(client, bufnr)
--           end,
--         },
--       }
--     end,
--   },
-- }
