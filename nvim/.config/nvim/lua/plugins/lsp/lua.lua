local keymaps = require("plugins.lsp.default_keymaps")
-- lua has some extra special config so it can work with runtime files
local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

return {
  on_attach = keymaps.setup_keymaps,
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
        -- Setup your lua path
        path = runtime_path,
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        -- Now, you don't get error/warning "Undefined global `vim`".
        globals = { "vim" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
      -- By default, lua-language-server sends anonymized data to its developers. Stop it using the following.
      telemetry = {
        enable = false,
      },
    },
  },
}
